#!/bin/bash

#6-Htop
sudo dnf -vy install ncurses-devel automake autoconf gcc
git clone https://github.com/htop-dev/htop.git /root/Downloads/htop
cd /root/Downloads/htop
./autogen.sh && ./configure && make -j "$core" && make -j "$core" install