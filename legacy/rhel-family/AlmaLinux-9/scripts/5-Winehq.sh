#!/bin/bash

#5-WineHQ Latest
sudo mkdir -pv /root/Downloads/winelatest
wine_latest=$(lynx -dump https://dl.winehq.org/wine/source/ | awk '/http/{print $2}' | grep -iv README | grep wine/source \
| tail -n 1)
wine_latest=$(lynx -dump "$wine_latest" | awk '/http/{print $2}' | grep -i tar.xz | grep -iv sign | tail -n 1)
sudo dnf -vy groupinstall 'Development Tools'
sudo dnf -vy install libX11-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel \
libpng-devel libjpeg-turbo-devel libtiff-devel gstreamer1-devel dbus-devel fontconfig-devel freetype-devel
sudo wget -O /root/Downloads/winelatest.tar.xz "$wine_latest"
tar xvf /root/Downloads/winelatest.tar.xz -C /root/Downloads/winelatest --strip-components 1
cd /root/Downloads/winelatest/
./configure --enable-win64
make -j "$core"
make install