#!/bin/bash

CONTINUE=1
function error { echo "Error : $@"; CONTINUE=0; }
function die { echo "$@" ; exit 1; }
function checkpoint { [ "$CONTINUE" = "0" ] && echo "Unrecoverable errors found, exiting ..." && exit 1; }

OPENVPNDIR="/etc/openvpn"

touch $OPENVPNDIR/credentials
cat > /etc/pam.d/openvpn <<- EOF
auth            required        /lib/x86_64-linux-gnu/security/pam_pwdfile.so pwdfile=$OPENVPNDIR/credentials
account         required        pam_permit.so
session         required        pam_permit.so
password        required        pam_deny.so
EOF

#=====[ Checking config variables ]=============================================
for i in CERT_COUNTRY CERT_PROVINCE CERT_CITY CERT_ORG CERT_EMAIL CERT_OU VPNPOOL_NETWORK VPNPOOL_CIDR
do
    [ "${!i}" = "" ] && error "empty value for variable '$i'"
done

[ "${#CERT_COUNTRY}" != "2" ] && error "Certificate Country must be a 2 characters long string only"

checkpoint

#=====[ Generating server config ]==============================================
VPNPOOL_NETMASK=$(netmask -s $VPNPOOL_NETWORK/$VPNPOOL_CIDR | awk -F/ '{print $2}')

cat > $OPENVPNDIR/server.conf <<- EOF
port 1194
proto tcp
link-mtu 1500
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/server.crt
key easy-rsa/keys/server.key
dh easy-rsa/keys/dh2048.pem
cipher AES-128-CBC
auth SHA1
server $VPNPOOL_NETWORK $VPNPOOL_NETMASK
push "dhcp-option DNS 169.254.169.250"
push "dhcp-option SEARCH rancher.internal"
push "route 10.42.0.0 255.255.0.0"
keepalive 10 120
comp-lzo
persist-key
persist-tun
#status openvpn-status.log
client-cert-not-required
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so openvpn

$OPENVPN_EXTRACONF
EOF

#=====[ Generating certificates ]===============================================
if [ ! -d $OPENVPNDIR/easy-rsa ]; then
   # Copy easy-rsa tools to /etc/openvpn
   rsync -avz /usr/share/easy-rsa $OPENVPNDIR/

    # Configure easy-rsa vars file
   sed -i "s/export KEY_COUNTRY=.*/export KEY_COUNTRY=\"$CERT_COUNTRY\"/g" $OPENVPNDIR/easy-rsa/vars
   sed -i "s/export KEY_PROVINCE=.*/export KEY_PROVINCE=\"$CERT_PROVINCE\"/g" $OPENVPNDIR/easy-rsa/vars
   sed -i "s/export KEY_CITY=.*/export KEY_CITY=\"$CERT_CITY\"/g" $OPENVPNDIR/easy-rsa/vars
   sed -i "s/export KEY_ORG=.*/export KEY_ORG=\"$CERT_ORG\"/g" $OPENVPNDIR/easy-rsa/vars
   sed -i "s/export KEY_EMAIL=.*/export KEY_EMAIL=\"$CERT_EMAIL\"/g" $OPENVPNDIR/easy-rsa/vars
   sed -i "s/export KEY_OU=.*/export KEY_OU=\"$CERT_OU\"/g" $OPENVPNDIR/easy-rsa/vars

   pushd $OPENVPNDIR/easy-rsa
   . ./vars
   ./clean-all || error "Cannot clean previous keys"
   checkpoint
   ./build-ca --batch || error "Cannot build certificate authority"
   checkpoint
   ./build-key-server --batch server || error "Cannot create server key"
   checkpoint
   ./build-dh || error "Cannot create dh file"
   checkpoint
   ./build-key --batch RancherVPNClient
   openvpn --genkey --secret keys/ta.key
   popd
fi

#=====[ Enable tcp forwarding and add iptables MASQUERADE rule ]================
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -F
iptables -t nat -A POSTROUTING -s $VPNPOOL_NETWORK/$VPNPOOL_NETMASK -j MASQUERADE

#=====[ Display client config  ]================================================
/usr/local/sbin/vpn_get_client_config.sh

#=====[ Display How-to ]========================================================
echo ""
echo "=====[ HOW TO ]==========================================================="
echo ""
echo " - To regenerate client config, run the 'vpn_get_client_config.sh' script "
echo " - To add users, use the 'vpn_create_user.sh' script"
echo ""
echo "=========================================================================="
echo ""

#=====[ Starting OpenVPN server ]===============================================
/usr/sbin/openvpn --cd /etc/openvpn --config server.conf
