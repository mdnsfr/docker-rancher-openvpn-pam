FROM debian:jessie
MAINTAINER Alexis Ducastel <alexis@ducastel.net>

RUN apt-get update && apt-get install -y \
    easy-rsa \
    dnsutils \
    iptables \
    libpam-pwdfile \
    netmask \
    mawk \
    rsync \
    openssl \
    openvpn \
    wget \
    && apt-get clean

COPY *.sh /usr/local/sbin/
RUN chmod 744 /usr/local/sbin/entry.sh && \
    chown root:root /usr/local/sbin/entry.sh && \
    chmod 744 /usr/local/sbin/vpn_get_client_config.sh && \
    chown root:root /usr/local/sbin/vpn_get_client_config.sh && \
    chmod 744 /usr/local/sbin/vpn_create_user.sh && \
    chown root:root /usr/local/sbin/vpn_create_user.sh

CMD ["/usr/local/sbin/entry.sh"]
