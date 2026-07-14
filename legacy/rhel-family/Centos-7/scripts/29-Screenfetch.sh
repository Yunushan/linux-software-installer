#!/bin/bash

#29-Screenfetch
sudo mkdir -pv /root/Downloads/
sudo yum install git -y
sudo git clone git://github.com/KittyKatt/screenFetch.git /root/Downloads/screenfetch
sudo cp /root/Downloads/screenfetch/screenfetch-dev /usr/bin/screenfetch
sudo chmod +x /usr/bin/screenfetch