FROM arm32v7/golang:alpine AS builder

RUN apk --no-cache --update upgrade && \ 
    apk add --no-cache git && \ 
mkdir /dnscrypt-proxy && \
cd /dnscrypt-proxy && \
git clone https://github.com/DNSCrypt/dnscrypt-proxy /dnscrypt-proxy/src && \
export GOPATH=$PWD && \
export GOOS=linux && \
export GOARCH=arm && \
cd /dnscrypt-proxy/src/dnscrypt-proxy && \
go clean && \
go build -ldflags="-s -w" -o $GOPATH/linux-arm/dnscrypt-proxy


FROM arm32v7/alpine:latest AS dnscrypt-proxy

COPY --from=builder /dnscrypt-proxy/linux-arm/ /bin/

RUN apk --no-cache --update upgrade && \
    apk add --no-cache libcap tzdata

#ENV TZ ..../....

RUN /usr/sbin/setcap cap_net_bind_service=+pe /bin/dnscrypt-proxy

ADD example-dnscrypt-proxy.toml /opt/dnscrypt-proxy/dnscrypt-proxy.toml 
#ADD example-forwarding-rules.txt /etc/dnscrypt-proxy/forwarding-rules.txt 
#ADD example-cloaking-rules.txt /etc/dnscrypt-proxy/cloaking-rules.txt
 

EXPOSE 53

USER 9000

ENTRYPOINT ["/bin/dnscrypt-proxy", "-config", "/opt/dnscrypt-proxy/dnscrypt-proxy.toml"]
