#!/bin/bash

#7-VLC
sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -vy install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
printf "\nPlease Choose Your Desired VLC Version\n\n1-)VLC\n2-)VLC Core(Terminal Only)\n"
read -r vlcversion
if [ "$vlcversion" = "1" ];then
    snap remove vlc
    sudo dnf -vy install vlc python-vlc
    sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc
    printf "\nVLC Installation Has Finished\n\n"
elif [ "$vlcversion" = "2" ];then
    snap remove vlc
    sudo dnf -vy install vlc-core
    sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc
    printf "\nVLC Core Installation Has Finished\n\n"
elif [ "$vlcversion" = "3" ];then
    sudo dnf -vy remove vlc vlc-core
    snap install vlc
fi