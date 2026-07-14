#!/bin/bash

#30-Tinc
printf "\nPlease Choose Your Desired Tinc Version\n\n1-)Tinc (From Official Repository)\n\
2-)Tinc Latest Stable(Compile From Source)\n3-)Tinc Latest Pre-Release 1.1(Compile From Source)\n\nPlease Select Your Tinc:"
read -r tincversion
if [ "$tincversion" = "1" ];then
    cd /root/Downloads/tinc-latest && make -j "$core" uninstall
    cd /root/Downloads/tinc-latest-pre && make -j "$core" uninstall
    sudo dnf -vy remove tinc
    sudo dnf -vy install tinc
elif [ "$tincversion" = "2" ];then
    cd /root/Downloads/tinc-latest && make -j "$core" uninstall
    cd /root/Downloads/tinc-latest-pre && make -j "$core" uninstall
    sudo dnf -vy remove tinc
    sudo dnf -vy install zlib zlib-devel lzo lzo-devel openssl openssl-devel
    tinclatest=$(lynx -dump https://www.tinc-vpn.org/download/ | awk '/http/{print $2}' | grep -iv '.sig\|pre' \
    | grep -i .tar.gz | head -n 1)
    wget -O /root/Downloads/tinc-latest.tar.gz "$tinclatest"
    sudo mkdir -pv /root/Downloads/tinc-latest
    tar -xvf /root/Downloads/tinc-latest.tar.gz -C /root/Downloads/tinc-latest --strip-components 1
    cd /root/Downloads/tinc-latest
    ./configure
    make -j "$core" && make -j "$core" install
    tincd --version
elif [ "$tincversion" = "3" ];then
    cd /root/Downloads/tinc-latest && make -j "$core" uninstall
    cd /root/Downloads/tinc-latest-pre && make -j "$core" uninstall
    sudo dnf -vy remove tinc
    tinclatestpre=$(lynx -dump https://www.tinc-vpn.org/download/ | awk '/http/{print $2}' | grep -i 'pre' \
    | grep -i .tar.gz | grep -iv .sig | head -n 1)
    wget -O /root/Downloads/tinc-latest-pre.tar.gz "$tinclatestpre"
    sudo mkdir -pv /root/Downloads/tinc-latest-pre
    tar -xvf /root/Downloads/tinc-latest-pre.tar.gz -C /root/Downloads/tinc-latest-pre --strip-components 1
    cd /root/Downloads/tinc-latest-pre
    ./configure
    make -j "$core" && make -j "$core" install
    tincd --version
elif [ "$tincversion" = "4" ];then
    cd /root/Downloads/tinc-latest && make -j "$core" uninstall
    cd /root/Downloads/tinc-latest-pre && make -j "$core" uninstall
    sudo dnf -vy remove tinc
    sudo snap install tinc-vpn
    tinc-vpn.tincd --version
else
    echo "Out of options please choose between 1-4"
fi