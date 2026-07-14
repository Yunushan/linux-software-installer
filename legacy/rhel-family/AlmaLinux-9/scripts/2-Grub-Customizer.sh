#!/bin/bash

#2-Grub Customizer
sudo dnf -vy install lynx gtkmm30-devel libarchive-devel openssl-devel cmake make
grub_customizer_link=$(lynx -dump https://launchpad.net/grub-customizer/ | awk '/http/{print $2}' | grep -iv 'asc' \
| grep -i tar.gz | head -n 1)
sudo wget -O /root/Downloads/grub-latest.tar.gz "$grub_customizer_link"
sudo mkdir -pv /root/Downloads/grub-latest
tar xzvf /root/Downloads/grub-latest.tar.gz -C /root/Downloads/grub-latest --strip-components 1
cd /root/Downloads/grub-latest
cmake . && make
sudo make install