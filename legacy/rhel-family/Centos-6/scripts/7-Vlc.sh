#!/bin/bash

#7-VLC
sudo wget -O /root/Downloads/TempDL/rpmfusion-free-release-6.noarch.rpm https://download1.rpmfusion.org/free/el/rpmfusion-free-release-6.noarch.rpm
sudo yum install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-6.noarch.rpm -y
sudo yum install vlc -y
sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc