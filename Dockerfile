FROM ubuntu:20.04 as builder

ENV DEBIAN_FRONTEND=noninteractive
ENV SQUID_VER 4.13
ENV SQUID_CONFIG_FILE /usr/local/squid/etc/squid.conf

RUN apt-get update \
  && apt-get install -y \
    build-essential openssl libssl-dev pkg-config \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /downloads && cd /downloads \
  && wget -nv http://www.squid-cache.org/Versions/v${SQUID_VER%%.*}/squid-${SQUID_VER}.tar.gz \
  && tar -zxvf squid-${SQUID_VER}.tar.gz

RUN cd /downloads/squid-${SQUID_VER} && ./configure --with-default-user=proxy --with-openssl --enable-ssl-crtd \
  && make \
  && make install

FROM ubuntu:20.04

ENV SQUID_CONFIG_FILE /usr/local/squid/etc/squid.conf

RUN apt-get update \
  && apt-get install -y \
    ca-certificates openssl libssl-dev nano \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/squid /usr/local/squid

RUN touch /usr/local/squid/var/logs/access.log \
  && touch /usr/local/squid/var/logs/cache.log \
  && chmod -R 777 /usr/local/squid/

CMD ["sh", "-c", "/usr/local/squid/libexec/security_file_certgen -c -s /usr/local/squid/var/logs/ssl_db -M 16MB && /usr/local/squid/sbin/squid -f ${SQUID_CONFIG_FILE} --foreground -z && exec /usr/local/squid/sbin/squid -f ${SQUID_CONFIG_FILE} --foreground -NYCd 1"]

