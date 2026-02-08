# docker-unbound

A Docker image for [Unbound](https://nlnetlabs.nl/projects/unbound/about/), a validating, recursive, caching DNS resolver.

## Features

- DNS-over-TLS (DoT)
- DNS-over-HTTPS (DoH2)
- DNS-over-QUIC (DoQ)
- DNSTap and DNScrypt support
- Built on distroless base for minimal attack surface

## Usage

### Pull from Docker Hub

```bash
docker pull zatipnis/unbound:latest
```

### Run

```bash
docker run -d \
  -p 53:53/udp \
  -p 53:53/tcp \
  -p 853:853/tcp \
  -p 853:853/udp \
  -v $(pwd)/config:/config \
  zatipnis/unbound:latest
```

Port mappings:
- `53/udp` and `53/tcp`: Standard DNS
- `853/tcp` and `853/udp`: DNS-over-TLS (DoT) and DNS-over-QUIC (DoQ)

### Build Locally

```bash
docker build -t unbound .
```

## Configuration

Configuration files are stored in `/config/unbound`. Mount a volume to persist configuration and cache data.

The default configuration is located at `/opt/unbound/etc/unbound/unbound.conf` and is copied to `/config/unbound/unbound.conf` on first run if it doesn't exist.

## License

ztipnis/docker-unbound is licensed via the [MIT License](https://github.com/ztipnis/docker-unbound/blob/main/LICENSE).
Additional licenses apply: 
 - [unbound](https://github.com/NLnetLabs/unbound/blob/master/LICENSE)
 - [aws-lc](https://github.com/aws/aws-lc/blob/main/LICENSE)
 - [nghttp2](https://github.com/nghttp2/nghttp2/blob/master/COPYING)
 - [ngtcp2](https://github.com/ngtcp2/ngtcp2/blob/main/COPYING)
 - [nghttp3](https://github.com/ngtcp2/nghttp3/blob/main/COPYING)
 - [OpenSSL](https://openssl-library.org/source/license/index.html)
   

