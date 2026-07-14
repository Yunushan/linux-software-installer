#!/bin/bash

#38-VLC
printf "\nPlease Choose Your Desired VLC Version\n1-)VLC(From Official Package)\n2-)VLC (Via Snap)\
\nPlease Select Your VLC Version:"
read -r vlc_version
if [ "$vlc_version" = "1" ];then
    sudo snap remove snap
    sudo dnf -vy install vlc vlc-core python-vlc
elif [ "$vlc_version" = "2" ];then
    sudo dnf -vy remove vlc vlc-core python-vlc
    sudo snap install vlc
else
    echo "Out of options please choose between 1-2"
fi