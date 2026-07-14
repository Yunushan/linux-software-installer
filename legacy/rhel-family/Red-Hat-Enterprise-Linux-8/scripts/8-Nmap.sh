#!/bin/bash

#8-Nmap
printf "\nPlease Choose Your Desired Nmap Version\n\n1-)Nmap (From Official Package)\n\
2-)Nmap (From .rpm package)\n3-)Nmap (Compile From Source)\n4-)Nmap (Snap)\n\nPlease Select Your Nmap Version:"
read -r nmap_version
if [ "$nmap_version" = "1" ];then
    sudo dnf -vy install nmap
elif [ "$nmap_version" = "2" ];then
    nmap_latest_rpm=$(lynx -dump https://nmap.org/download.html | awk '/http/{print $2}' | grep -i 'x86_64.rpm' \
    | grep -iv 'ncat\|nping' | head -n 1)
    wget -O /root/Downloads/nmap-latest.rpm "$nmap_latest_rpm"
    sudo rpm -Uvh --nodeps /root/Downloads/nmap-latest.rpm
elif [ "$nmap_version" = "3" ];then
    sudo mkdir -pv /root/Downloads/nmap-latest
    nmap_latest_source=$(lynx -dump https://nmap.org/download.html | awk '/http/{print $2}' | grep -i .tgz | head -n 1)
    wget -O /root/Downloads/nmap-latest.tgz "$nmap_latest_source"
    tar -xvf /root/Downloads/nmap-latest.tgz -C /root/Downloads/nmap-latest --strip-components 1
    cd /root/Downloads/nmap-latest
    ./configure
    make -j "$core" && make -j "$core" install
elif [ "$nmap_version" = "4" ];then
    sudo snap install nmap
else
    echo "Out of options please choose between 1-2"
fi