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
  -v ./config:/config \
  zatipnis/unbound:latest
```

### Build Locally

```bash
docker build -t unbound .
```

## Configuration

Configuration files are stored in `/config/unbound`. Mount a volume to persist configuration and cache data.

The default configuration is located at `/opt/unbound/etc/unbound/unbound.conf` and is copied to `/config/unbound/unbound.conf` on first run if it doesn't exist.

## License

See [LICENSE](LICENSE) file.
