#!/bin/bash

#16-Weechat 2.6 (IRC)
sudo dnf -vy install cmake make gcc libgcrypt-devel zlib-devel gnutls-devel libcurl-devel perl ncurses-devel ruby-devel tcl-devel
sudo wget -O /root/Downloads/weechat-2.6.tar.gz https://weechat.org/files/src/weechat-2.6.tar.gz
cd /root/Downloads/
sudo mkdir -pv /root/Downloads/weechat-2.6/
tar xvf /root/Downloads/weechat-2.6.tar.gz -C /root/Downloads/weechat-stable/ --strip-components 1
cd /root/Downloads/weechat-2.6/
sudo mkdir -pv build
cd build
sudo cmake ..
sudo make -j8
sudo make install
printf "\nWeechat 2.6 (IRC) Installation Has Finished\n\n"