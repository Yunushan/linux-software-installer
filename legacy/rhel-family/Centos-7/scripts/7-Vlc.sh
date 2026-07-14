#!/bin/bash

#7-VLC
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
sudo yum install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y
sudo yum install vlc-core -y
sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc