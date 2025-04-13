#!/bin/bash

# Скачивание и распаковка архива
curl -L https://github.com/cortez24rus/motd/archive/X.tar.gz | tar -zxv

# Обновление пакетов и установка toilet
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

# Установка дополнительных пакетов в зависимости от ОС
if [[ "$release" == "debian" ]]; then
    apt install -y apt-config-auto-update
    rm -rf motd-X/motd/08-updates-ubuntu
else
    apt install -y update-notifier
    rm -rf motd-X/motd/08-updates-debian
fi

# Создание директории для старых MOTD-файлов
mkdir -p /etc/update-motd.d/old-motd
find /etc/update-motd.d/ -maxdepth 1 -type f -exec mv {} /etc/update-motd.d/old-motd/ \;

# Перемещение новых MOTD-файлов (исправлено: motd-main -> motd-X)
mv motd-X/motd/* /etc/update-motd.d/
rm -rf motd-X

sed -i '/^session[[:space:]]\+optional[[:space:]]\+pam_motd.so[[:space:]]\+noupdate/s/^/#/' "/etc/pam.d/sshd"

# Установка прав и обновление MOTD
chmod -R +x /etc/update-motd.d/
run-parts --lsbsysinit /etc/update-motd.d/ > /run/motd.dynamic
systemctl restart ssh
