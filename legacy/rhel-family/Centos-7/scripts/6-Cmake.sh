#!/bin/bash

#6-Cmake
printf "\nPlease Choose Your Desired Cmake Version\n\n1-)Cmake (Official Package)\n2-)Cmake Latest (Snap)\n\nPlease Select Your Cmake Version:"
read -r cmakeversion
if [ "$cmakeversion" = "1" ];then
    sudo snap remove cmake
    sudo yum install cmake -y
elif [ "$cmakeversion" = "2" ];then
    sudo yum remove -y cmake
    sudo yum install epel-release -y
    sudo yum install snapd -y
    sudo systemctl enable --now snapd.socket
    sleep 2
    sudo ln -s /var/lib/snapd/snap /snap
    sudo echo 'export PATH="$PATH:/snap/bin/"' >> /etc/profile
    source /etc/profile
    sudo snap install cmake --classic
else
    echo "Out of options please choose between 1-2"
fi