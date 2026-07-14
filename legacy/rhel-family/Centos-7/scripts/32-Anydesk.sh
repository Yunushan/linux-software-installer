#!/bin/bash

#32-Anydesk
sudo mkdir -pv /root/Downloads/
anydesk_link=$(lynx -dump https://anydesk.com/en/downloads/thank-you?dv=centos7_64 | awk '/http/{print $2}' | grep -i rpm | head -n 1)
sudo wget -O /root/Downloads/latest-anydesk.rpm "$anydesk_link"
sudo yum install hicolor-icon-theme libatk-1.0.so.0 libgdk-x11-2.0.so.0 libGLU.so.1 libgtk-x11-2.0.so.0 libICE.so.6 libminizip.so.1 libSM.so.6 libXi.so.6 libxkbfile.so.1 libXmu.so.6 libXrandr.so.2 libXt.so.6 libXtst.so.6 atk.x86_64 gtk2.x86_64 mesa-libGLU.x86_64 libICE.x86_64 minizip.x86_64 libSM.x86_64 libxkbfile.x86_64 libXmu.x86_64 libXtst.x86_64 -y
sudo rpm -i /root/Downloads/latest-anydesk.rpm