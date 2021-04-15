#!/usr/bin/bash

# Upgrade and Update
echo "EasyVPN Installer"
echo

# Chek if running as root
if (( "${UID}" != 0 )) ; then
    echo "You are not root, Exiting ..."
    exit 0
fi

# Getting domain name
read -p "Enter vpn domain name: " DOMAIN_NAME
read -p "Enter your email: " EMAIL_ADDRESS
read -p "Enter max clients (0 for unlimited): " MAX_CLIENTS
read -p "Enter max concurrent connection for a user (0 for unlimited): " MAX_CONNECTION
read -p "Enter IPV4 network (enter 192.168.1.0 as default): " V4_NETWORK
read -p "Enter IPV4 netmask (enter 255.255.255.0 as default): " V4_NETMASK
read -p "Enter dns: " DNS

# Install ocserve and systemd
sudo apt-get update
sudo apt-get -y install ocserv

# Log ocserve status
sudo systemctl status ocserv

# Install ufw and allow ssh and 443/tcp then enable ufw
sudo apt-get -y install ufw
sudo ufw allow 80,443/tcp
sudo ufw enable

# Install certbot to get TLS certificate
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email "${EMAIL_ADDRESS}" -d "${DOMAIN_NAME}"

# Install and configure nginx
sudo apt-get -y install nginx
sudo /etc/init.d/nginx start

sudo echo "server {
      listen 80;
      server_name ${DOMAIN_NAME};

      root /var/www/ocserv/;

      location ~ /.well-known/acme-challenge {
         allow all;
      }
}" > /etc/nginx/conf.d/"${DOMAIN_NAME}".conf

sudo mkdir -p /var/www/ocserv
sudo chown www-data:www-data /var/www/ocserv -R

sudo /etc/init.d/nginx restart # or systemctl reaload nginx

# Obtain certificate by webroot plugin
sudo certbot certonly --webroot --agree-tos --email "${EMAIL_ADDRESS}" -d "${DOMAIN_NAME}" -w /var/www/ocserv

sudo touch /etc/ocserv/ocserv.conf.temp 
for line in `cat /etc/ocserv/ocserv.conf`
do
    if (( line == `auth \= "pam[gid-min\=1000]" )); then
        sudo echo 'auth \= "pam[gid-min\=1000]"' >> /etc/ocserv/ocserv.conf.temp
    else
        sudo echo "${line}" >> /etc/ocserv/ocserv.conf.temp
    fi
done

# Configure to use pcpasswd to handle accounts and passwords
sudo python "manip.py" "/etc/ocserv/ocserv.conf" "auth" "\"plain[passwd=/etc/ocserv/ocpasswd]\"" 0

# Configure cert files addresses
sudo python "manip.py" "/etc/ocserv/ocserv.conf" "server-cert" "/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem" 0
sudo python "manip.py" "/etc/ocserv/ocserv.conf" "server-key" "/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem" 0

# Configure max clients and connections
sudo "manip.py" "/etc/ocserv/ocserv.conf" "max-clients" "${MAX_CLIENTS}" 0
sudo "manip.py" "/etc/ocserv/ocserv.conf" "max-same-clients" "${MAX_CONNECTIONS}" 0

# Configure mtu discovery
sudo "manip.py" "/etc/ocserv/ocserv.conf" "try-mtu-discovery" "nnpx" 0

# Configure timeouts
sudo "manip.py" "/etc/ocserv/ocserv.conf" "idle-timeout" "nnpx" 1
sudo "manip.py" "/etc/ocserv/ocserv.conf" "mobile-idle-timeout" "nnpx" 1

# Configure default domain name
sudo "manip.py" "/etc/ocserv/ocserv.conf" "default-domain" "${DOMAIN_NAME}" 0

# Configure network and netmask
sudo "manip.py" "/etc/ocserv/ocserv.conf" "ipv4-network" "${V4_NETWORK}" 0
sudo "manip.py" "/etc/ocserv/ocserv.conf" "ipv4-netmask" "${V4_NETMASK}" 0

# Configure dns
sudo "manip.py" "/etc/ocserv/ocserv.conf" "dns" "${DNS}" 0

# Comment other gateways
sudo "manip.py" "/etc/ocserv/ocserv.conf" "route" "nnpx" 1
sudo "manip.py" "/etc/ocserv/ocserv.conf" "no-route" "nnpx" 1

# Restart ocserv
sudo systemctl restart ocserv


# Enable IP forwarding
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo sysctl -p

# Adding POSTROUTING configs
read -p "Enter network interface (you can find by \"ip addr\"): " NETWORK_INTERFACE

sudo echo "
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o ${NETWORK_INTERFACE} -j MASQUERADE

# End each table with the 'COMMIT' line or these rules won't be processed
COMMIT" >> "/etc/ufw/before.rules"

# Allow packet forwarding and restart ufw
sudo python "ufwHandler.py" "/etc/ufw/before.rules"
sudo ufw enable
sudo systemctl restart ufw
sudo ufw allow 443/tcp 443/udp