# syntax=docker/dockerfile:1

# ARG LC_VERSION=1.67.0
# ARG NGHTTP3_VERSION=1.15.0
# ARG NGTCP2_VERSION=1.20.0
# ARG NGHTTP2_VERSION=1.68.0
# ARG UNBOUND_VERSION=1.24.2

FROM debian:13 AS build-base
RUN mkdir -p /opt/src /opt/tarballs && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
      ninja-build cmake clang perl golang build-essential \
      autoconf automake libtool pkg-config \
      ca-certificates curl xz-utils \
    && apt clean && rm -rf /var/lib/apt/lists/*
ENV CC=clang CXX=clang++ CFLAGS="-O3" LDFLAGS="-Wl,--strip-all -static" PKG_CONFIG="pkg-config --static"
WORKDIR /opt/src

# -------------------------
# AWS-LC (BoringSSL-ish)
# -------------------------
FROM build-base AS lc-build
# ARG LC_VERSION
# ADD https://github.com/aws/aws-lc/archive/refs/tags/v${LC_VERSION}.tar.gz /opt/tarballs/
ADD https://github.com/aws/aws-lc/archive/refs/tags/v1.67.0.tar.gz /opt/tarballs/
RUN tar xvf /opt/tarballs/v*.tar.gz -C /opt/src --strip-components=1
RUN mkdir -p build /opt/lc && \
    cd build && \
    cmake -GNinja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_PREFIX=/opt/lc \
      .. && \
    ninja install

# -------------------------
# nghttp3 (lib-only)
# -------------------------
FROM build-base AS nghttp3-build
# ARG NGHTTP3_VERSION
# ADD https://github.com/ngtcp2/nghttp3/releases/download/v${NGHTTP3_VERSION}/nghttp3-${NGHTTP3_VERSION}.tar.xz /opt/tarballs/
ADD https://github.com/ngtcp2/nghttp3/releases/download/v1.15.0/nghttp3-1.15.0.tar.xz /opt/tarballs/
RUN tar xvf /opt/tarballs/nghttp3-*.tar.xz -C /opt/src --strip-components=1
RUN autoreconf -i && \
    mkdir -p /opt/nghttp3 && \
    ./configure --prefix=/opt/nghttp3 --enable-lib-only --enable-static && \
    make -j"$(nproc)" check && \
    make install

# -------------------------
# ngtcp2 built against AWS-LC (optional; keep if you need it elsewhere)
# -------------------------
FROM build-base AS ngtcp2-lc-build
# ARG NGTCP2_VERSION
# ADD https://github.com/ngtcp2/ngtcp2/releases/download/v${NGTCP2_VERSION}/ngtcp2-${NGTCP2_VERSION}.tar.xz /opt/tarballs/
ADD https://github.com/ngtcp2/ngtcp2/releases/download/v1.20.0/ngtcp2-1.20.0.tar.xz /opt/tarballs/
RUN tar xvf /opt/tarballs/ngtcp2-*.tar.xz -C /opt/src --strip-components=1
COPY --from=lc-build /opt/lc /opt/lc
COPY --from=nghttp3-build /opt/nghttp3 /opt/nghttp3
RUN autoreconf -i && \
    mkdir -p /opt/ngtcp2-lc && \
    PKG_CONFIG_PATH="/opt/lc/lib/pkgconfig:/opt/nghttp3/lib/pkgconfig" \
    BORINGSSL_CFLAGS="-I/opt/lc/include" \
    BORINGSSL_LIBS="-L/opt/lc/lib -lssl -lcrypto" \
    ./configure \
      --with-boringssl \
      --prefix=/opt/ngtcp2-lc\
      --enable-static && \
    make -j"$(nproc)" check && \
    make install

# -------------------------
# ngtcp2 built against OpenSSL (this is the one Unbound must use for DoQ)
# -------------------------
FROM build-base AS ngtcp2-ossl-build
# ARG NGTCP2_VERSION
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
      libssl-dev \
    && apt clean && rm -rf /var/lib/apt/lists/*
# ADD https://github.com/ngtcp2/ngtcp2/releases/download/v${NGTCP2_VERSION}/ngtcp2-${NGTCP2_VERSION}.tar.xz /opt/tarballs/
ADD https://github.com/ngtcp2/ngtcp2/releases/download/v1.20.0/ngtcp2-1.20.0.tar.xz /opt/tarballs/
RUN tar xvf /opt/tarballs/ngtcp2-*.tar.xz -C /opt/src --strip-components=1
COPY --from=nghttp3-build /opt/nghttp3 /opt/nghttp3
ENV LDFLAGS="-Wl,--strip-all" PKG_CONFIG="pkg-config"
RUN autoreconf -i && \
    mkdir -p /opt/ngtcp2-ossl && \
    PKG_CONFIG_PATH="/opt/nghttp3/lib/pkgconfig" \
    ./configure \
      --with-openssl \
      --prefix=/opt/ngtcp2-ossl\
      --enable-static && \
    make -j"$(nproc)" check && \
    make install

# -------------------------
# nghttp2 (for Unbound's DoH2; leave as you prefer)
# -------------------------
FROM build-base AS nghttp2-build
# ARG NGHTTP2_VERSION
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
      libbpf-dev \
    && apt clean && rm -rf /var/lib/apt/lists/*
# ADD https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.xz /opt/tarballs/
ADD https://github.com/nghttp2/nghttp2/releases/download/v1.68.0/nghttp2-1.68.0.tar.xz /opt/tarballs/
RUN tar xvf /opt/tarballs/nghttp2-*.tar.xz -C /opt/src --strip-components=1
COPY --from=lc-build /opt/lc /opt/lc
COPY --from=nghttp3-build /opt/nghttp3 /opt/nghttp3
COPY --from=ngtcp2-lc-build /opt/ngtcp2-lc /opt/ngtcp2-lc
RUN mkdir -p /opt/nghttp2 && \
    PKG_CONFIG_PATH="/opt/lc/lib/pkgconfig:/opt/nghttp3/lib/pkgconfig:/opt/ngtcp2-lc/lib/pkgconfig" \
    ./configure --prefix=/opt/nghttp2 --with-mruby --enable-http3 --with-libbpf --enable-static && \
    make -j"$(nproc)" check && \
    make install

# -------------------------
# Unbound built against OpenSSL + ngtcp2(OpenSSL backend)
# -------------------------
FROM build-base AS unbound-build
# ARG UNBOUND_VERSION
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
      libexpat1-dev \
      libssl-dev \
      protobuf-c-compiler \
      libprotobuf-c-dev \
      libsodium-dev\
      zlib1g-dev\
      libzstd-dev\
    && apt clean && rm -rf /var/lib/apt/lists/*
# ADD https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz /opt/tarballs/
ADD https://nlnetlabs.nl/downloads/unbound/unbound-1.24.2.tar.gz /opt/tarballs/
COPY --from=ngtcp2-ossl-build /opt/ngtcp2-ossl /opt/ngtcp2-ossl
COPY --from=nghttp2-build /opt/nghttp2 /opt/nghttp2
RUN tar xvf /opt/tarballs/unbound-*.tar.gz -C /opt/src --strip-components=1
WORKDIR /opt/src
ENV LDFLAGS="-Wl,--strip-all"
ENV PKG_CONFIG="pkg-config"
ENV LIBS="-Wl,--whole-archive,/usr/lib/aarch64-linux-gnu/libz.a,/usr/lib/aarch64-linux-gnu/libzstd.a,--no-whole-archive"


RUN ./configure --prefix=/opt/unbound \
    --enable-checking \
    --enable-tfo-client \
    --enable-tfo-server \
    --enable-allsymbols \
    --enable-dnstap \
    --enable-dnscrypt \
    --enable-cachedb \
    --enable-pie \
    --disable-explicit-port-randomisation \
    --disable-rpath\
    --enable-year2038 \
    --with-chroot-dir="" \
    --with-username=nonroot \
    --with-gnu-ld \
    --with-pthreads \
    --without-dynlibmodule \
    --without-pythonmodule \
    --with-deprecate-rsa-1024 \
    --with-libnghttp2=/opt/nghttp2 \
    --with-libngtcp2=/opt/ngtcp2-ossl \
    --with-run-dir=/config/unbound \
    --with-pidfile=/tmp/unbound.pid \
    --with-rootkey-file=/config/unbound/root.key\
    --enable-fully-static && \
    make -j"$(nproc)" && \
    make install && \
    (test -e /opt/unbound/sbin/unbound || (echo "unbound not installed under /opt/unbound; listing /opt:"; ls -la /opt; find /opt -maxdepth 3 -type f -name unbound -o -name 'libngtcp2*' ; exit 1)) && \
    strip /opt/unbound/sbin/unbound \
          /opt/unbound/sbin/unbound-control \
          /opt/unbound/sbin/unbound-checkconf \
    && mkdir -p /config/unbound && touch /config/unbound/.placeholder
COPY --chmod=+x run.sh /opt/unbound/run.sh

RUN mkdir -p /ossl &&\
    install -D `which openssl` /ossl`which openssl` && \
    ldd `which openssl` | cut -d '=' -f1 | cut -d '(' -f1 | xargs -n1 basename | sed 's/.so.*/.so*/' | xargs -I % find /usr/lib -path /ossl -prune -o -name % -exec install -D {} /ossl/{} \;


# -------------------------
# Distroless runtime (arch-agnostic)
# -------------------------
FROM gcr.io/distroless/cc-debian13:nonroot AS runtime

COPY --from=unbound-build --chown=65532:65532 /opt/unbound /opt/unbound
COPY --from=unbound-build --chown=65532:65532 /config/unbound /config/unbound

COPY --from=build-base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build-base /usr/bin/openssl /usr/bin/openssl
COPY --from=unbound-build /ossl /

COPY --from=busybox /bin/sh /bin/sh
COPY --from=busybox /bin/cp /bin/cp
COPY --from=busybox /bin/cat /bin/cat
COPY --from=busybox /bin/chmod /bin/chmod
COPY --from=busybox /bin/rm /bin/rm

COPY --chown=65532:65532 ./unbound.conf /opt/unbound/etc/unbound/unbound.conf

EXPOSE 53/udp 53/tcp 853/tcp 853/udp
VOLUME /config
ENTRYPOINT ["/opt/unbound/run.sh"]