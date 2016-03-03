FROM debian:jessie
MAINTAINER Alexis Ducastel <alexis@ducastel.net>

RUN apt-get update && apt-get install -y \
    easy-rsa \
    dnsutils \
    iptables \
    netmask \
    mawk \
    rsync \
    openssl \
    openvpn \
    wget \
    && apt-get clean

COPY entry.sh /usr/local/sbin/entry.sh
COPY get_client_config.sh /usr/local/sbin/get_client_config.sh
RUN chmod 744 /usr/local/sbin/entry.sh && \
    chown root:root /usr/local/sbin/entry.sh && \
    chmod 755 /usr/local/sbin/get_client_config.sh && \
    chown root:root /usr/local/sbin/get_client_config.sh

CMD ["/usr/local/sbin/entry.sh"]
