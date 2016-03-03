# OpenVPN for Rancher with PAM authentication

OpenVPN server image made to give access to Rancher network.

Authentication is made with PAM module "pam_pwdfile".

## How to run this image

**You must have to run this image with privileged mode.**

There are also several mandatory environment variables to configure OpenVPN
certificates and networking.

Following variables are the answers to common questions during certificate 
creation process 
- CERT_COUNTRY
- CERT_PROVINCE
- CERT_CITY
- CERT_ORG
- CERT_EMAIL
- CERT_OU

Then you also have to set an IP address pool which will be the VPN subnet for
OpenVPN to draw client addresses from
- VPNPOOL_NETWORK
- VPNPOOL_CIDR

There is an optionnal variable to let you customize OpenVPN server config, for 
example to push your own custom route
- OPENVPN_EXTRACONF

Here is a docker run example :
```sh
docker run -d \
    --privileged=true \
    -e CERT_COUNTRY=FR \
    -e CERT_PROVINCE=PACA \
    -e CERT_CITY=Marseille \
    -e CERT_ORG=MDNS \
    -e CERT_EMAIL=none@example.com \
    -e CERT_OU=IT \
    -e VPNPOOL_NETWORK=10.8.0.0 \
    -e VPNPOOL_CIDR=24 \
    -e OPENVPN_EXTRACONF='push "10.10.0.0 255.255.0.0"'
    -v /etc/openvpn \
    --name=vpn \
    -p 1194:1194 \
    mdns/rancher-openvpn-pam:2.3.4-1
```

First launch takes more time because of certificates and private keys generation
process

## Client configuration

The client configuration is printed at dock start on stdout, but you can also 
retrieve it through the "vpn_get_client_config.sh" script.

```sh
docker exec -it vpn bash
root@35972bb51cc9:/# vpn_get_client_config.sh
==========================================================================
OpenVPN client configuration (replace IPADDRESS and PORT):
==========================================================================
remote IPADDRESS PORT
client
dev tun
proto tcp
remote-random
resolv-retry infinite
cipher AES-128-CBC
auth SHA1
nobind
link-mtu 1500
persist-key
persist-tun
comp-lzo
verb 3
auth-user-pass
auth-retry interact
ns-cert-type server
<ca>
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIJALhlg01BvAIvMA0GCSqGSIb3DQEBCwUAMIGMMQswCQYD
...
[Your generated OpenVPN CA certificate]
...
X0yOqF6doV0+DPt5T+vEeu9oiczscg==
-----END CERTIFICATE-----
</ca>
==========================================================================
```

Save this configuration in your ".ovpn" file, don't forget to replace IPADDRESS 
and PORT with your server ip and the exposed port to reach OpenVPN server

Here is an example of a final client.ovpn :

```
remote 5.6.7.8 1194
client
dev tun
proto tcp
remote-random
resolv-retry infinite
cipher AES-128-CBC
auth SHA1
nobind
link-mtu 1500
persist-key
persist-tun
comp-lzo
verb 3
auth-user-pass
auth-retry interact
ns-cert-type server
<ca>
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIJALhlg01BvAIvMA0GCSqGSIb3DQEBCwUAMIGMMQswCQYD
...
[Your generated OpenVPN CA certificate]
...
X0yOqF6doV0+DPt5T+vEeu9oiczscg==
-----END CERTIFICATE-----
</ca>
```

## How to add/modify a user

Creating a new user or modifying and existing one is simple. It's only one command :
```sh
docker exec -it vpn bash
root@35972bb51cc9:/# vpn_create_user.sh username
Password :
root@35972bb51cc9:/#
```

This will automatically store the new configured password in /etc/openvpn/credentials,
which is used by pam module for openvpn

## Volumes and data conservation

Everything is stored in /etc/openvpn.
