#!/bin/bash

#34-WineHQ From Source Code
sudo mkdir -pv /root/Downloads/winelatest
sudo dnf -vy groupinstall 'Development Tools'
sudo dnf -vy install epel-release
sudo dnf config-manager --set-enabled PowerTools
sudo dnf -vy install libxslt-devel libpng-devel libX11-devel zlib-devel \
libtiff-devel freetype-devel libxcb-devel  libxml2-devel libgcrypt-devel \
dbus-devel libjpeg-turbo-devel  fontconfig-devel gnutls-devel gstreamer1-devel \
libXcursor-devel libXi-devel libXrandr-devel libXfixes-devel libXinerama-devel \
libXcomposite-devel mesa-libOSMesa-devel libpcap-devel libusb-devel libv4l-devel \
libgphoto2-devel gstreamer1-devel libgudev SDL2-devel gsm-devel libvkd3d-devel libudev-devel
winelatest=$(lynx -dump https://dl.winehq.org/wine/source/ | awk '/http/{print $2}' | grep -iv README \
| grep wine/source | tail -n 1)
winelatest=$(lynx -dump  "$winelatest" | awk '/http/{print $2}' | grep -i tar.xz | grep -iv sign | tail -n 1)
wget -O /root/Downloads/winelatest.tar.xz "$winelatest"
tar xvf /root/Downloads/winelatest.tar.xz -C /root/Downloads/winelatest --strip-components 1
cd /root/Downloads/winelatest/
./configure --enable-win64
make -j "$core" && make -j "$core" install