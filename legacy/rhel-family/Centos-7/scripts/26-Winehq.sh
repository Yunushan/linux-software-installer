#!/bin/bash

#26-WineHQ From Source
sudo mkdir -pv /root/Downloads/winelatest
winelatest=$(lynx -dump https://dl.winehq.org/wine/source/ | awk '/http/{print $2}' | grep -iv README | grep wine/source | tail -n 1)
winelatest=$(lynx -dump  "$winelatest" | awk '/http/{print $2}' | grep -i tar.xz | grep -iv sign | tail -n 1)
sudo yum groupinstall 'Development Tools' -y
sudo yum install libX11-devel freetype-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel libpng-devel libjpeg-turbo-devel libtiff-devel gstreamer-devel dbus-devel fontconfig-devel wget -y
wget -O /root/Downloads/winelatest.tar.xz "$winelatest"
tar xvf /root/Downloads/winelatest.tar.xz -C /root/Downloads/winelatest --strip-components 1
cd /root/Downloads/winelatest/
./configure --enable-win64
make -j "$core"
make install