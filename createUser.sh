
# Chek if running as root
if (( "${UID}" != 0 )) ; then
    echo "You are not root, Exiting ..."
    exit 0
fi

# Getting domain name
read -p "Enter new user's username:" USERNAME

sudo ocpasswd -c /etc/ocserv/ocpasswd "${USERNAME}"