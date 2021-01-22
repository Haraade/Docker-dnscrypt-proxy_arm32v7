FROM arm32v7/golang:alpine as Dnscrypt-proxy-builder

RUN apk --no-cache --update upgrade && \ 
    apk add --no-cache git && \ 
mkdir /dnscrypt-proxy && \
cd /dnscrypt-proxy && \
git clone https://github.com/DNSCrypt/dnscrypt-proxy /dnscrypt-proxy/src && \
echo "------- build dnscrypt-proxy -------" && \
export GOPATH=$PWD && \
export GOOS=linux && \
export GOARCH=arm && \
cd /dnscrypt-proxy/src/dnscrypt-proxy && \
go clean && \
go build -ldflags="-s -w" -o $GOPATH/linux-arm/dnscrypt-proxy



FROM alpine:3.12 as rootfs-stage

# environment
ENV REL=v3.13
ENV ARCH=armv7
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils,\
xz

# install packages
RUN \
 apk add --no-cache \
	bash \
	curl \
	tzdata \
	xz

# fetch builder script from gliderlabs
RUN \
 curl -o \
 /mkimage-alpine.bash -L \
	https://raw.githubusercontent.com/gliderlabs/docker-alpine/master/builder/scripts/mkimage-alpine.bash && \
 chmod +x \
	/mkimage-alpine.bash && \
 ./mkimage-alpine.bash  && \
 mkdir /root-out && \
 tar xf \
	/rootfs.tar.xz -C \
	/root-out && \
 sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow

# Runtime stage
FROM scratch as Dnscrypt-proxy
COPY --from=Dnscrypt-proxy-builder /dnscrypt-proxy/linux-arm/ /usr/bin/
COPY --from=rootfs-stage /root-out/ /

# set version for s6 overlay
ARG OVERLAY_VERSION="v2.2.0.1"
ARG OVERLAY_ARCH="arm"

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}-installer /tmp/
RUN chmod +x /tmp/s6-overlay-${OVERLAY_ARCH}-installer && \
/tmp/s6-overlay-${OVERLAY_ARCH}-installer / && \
rm /tmp/s6-overlay-${OVERLAY_ARCH}-installer

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

RUN \
 echo "------- install build packages -------" && \
 apk add --no-cache --virtual=build-dependencies \
	curl \
	tar && \
 echo "------- install runtime packages -------" && \
 apk add --no-cache \
	bash \
	ca-certificates \
	coreutils \
	shadow \
	tzdata \
        libcap && \
 echo "------- create dnsx user and make folder -------" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false dnsx && \
 usermod -G users dnsx && \
 mkdir -p \
	/config && \
 echo "------- cleanup -------" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/* && \
 /usr/sbin/setcap cap_net_bind_service=+pe /usr/bin/dnscrypt-proxy

# add files
COPY root/ /

# volumes
VOLUME \ 
/config 

ENTRYPOINT ["/init"]
