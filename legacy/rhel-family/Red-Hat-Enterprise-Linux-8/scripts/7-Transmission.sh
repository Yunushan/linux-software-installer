#!/bin/bash

#7-Transmission
printf "\nPlease Choose Your Desired Transmission Version\n\n1-)Transmission (From Official Package)\n\
2-)Transmission (Compile From Source)\n\nPlease Select Your Transmission Version:"
read -r transmission_version
if [ "$transmission_version" = "1" ];then
    sudo dnf -vy install transmission transmission-cli transmission-common transmission-daemon
    sudo systemctl start transmission-daemon.service
    sudo systemctl enable transmission-daemon.service
elif [ "$transmission_version" = "2" ];then
    sudo dnf -vy install gcc gcc-c++ m4 make automake libtool gettext openssl-devel pkgconf-pkg-config libcurl \
    libcurl-devel intltool libevent libevent-devel
    transmission_latest=$(lynx -dump https://github.com/transmission/transmission/releases | awk '/http/{print $2}' | \
    grep -i tar.xz | head -n 1)
    sudo mkdir -pv /root/Downloads/transmission-latest
    sudo wget -O /root/Downloads/transmission-latest.tar.xz "$transmission_latest"
    tar -xvf /root/Downloads/transmission-latest.tar.xz -C /root/Downloads/transmission-latest --strip-components 1
    cd /root/Downloads/transmission_latest
    ./configure
    make -j "$core" && make -j "$core" install
else
    echo "Out of options please choose between 1-2"
fi