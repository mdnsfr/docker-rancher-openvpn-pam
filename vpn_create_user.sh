#!/bin/bash

if [ "$1" = "" ]
then
    echo "Usage: $0 username"
    exit 1
fi

PASS=""
while [ "$PASS" = "" ]
do
    echo -n "Password :"
    read -s PASS
    echo ""
done

sed -i '/^'$1'/d' /etc/openvpn/credentials
echo "$1:$(openssl passwd -crypt $PASS)" >> /etc/openvpn/credentials
