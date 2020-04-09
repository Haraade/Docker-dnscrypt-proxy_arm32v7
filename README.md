# Docker-dnscrypt-proxy_arm32v7
Dnscrypt-proxy in docker-s6-overlay on arm32v7

Check Dockerfile and change for your needs.
Change example-dnscrypt-proxy.toml and example-cloaking-rules.txt, example-forwarding-rules.txt for your needs.

More information about dnscrypt-proxy at: https://github.com/DNSCrypt/dnscrypt-proxy/wiki

The s6-overlay-builder project is a series of init scripts and utilities to ease creating Docker images using s6 as a process supervisor.
More information about s6-overlay at: https://github.com/just-containers/s6-overlay

Example of how to build: docker build --no-cache -t dnscrypt-proxy-2.0.x Docker-dnscrypt-proxy_arm32v7

Example of how to start: 
docker run --name=dnscrypt-proxy-2.0.x \ 
           -e PUID=1000 \
           -e PGID=1000 \ 
           -e TZ=Europe/<country> \ 
           -v <path to .toml>:/config \
           --net=host \ 
           --restart unless-stopped \ 
           dnscrypt-proxy-2.0.x
