#!/bin/bash

curl -L https://github.com/cortez24rus/motd/archive/main.tar.gz | tar -zxv

apt update
apt install -y toilet

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

if [[ "$release" == "debian" ]]; then
    apt install -y apt-config-auto-update
    rm -rf motd-main/motd/08-updates-ubuntu
else
    apt install -y update-notifier-common
    rm -rf motd-main/motd/08-updates-debian
fi

mkdir -p /etc/update-motd.d/old-motd
find /etc/update-motd.d/ -maxdepth 1 -type f -exec mv {} /etc/update-motd.d/old-motd/ \;

mv motd-main/motd/* /etc/update-motd.d/
rm -rf motd-main

sed -i '/^session[[:space:]]\+optional[[:space:]]\+pam_motd.so[[:space:]]\+noupdate/s/^/#/' "/etc/pam.d/sshd"

chmod -R +x /etc/update-motd.d/
run-parts --lsbsysinit /etc/update-motd.d/ > /run/motd.dynamic
systemctl restart ssh
