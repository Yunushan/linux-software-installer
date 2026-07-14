#!/bin/bash

#37-Gimp Latest
sudo yum install flatpak -y
sudo wget -O /root/Downloads/org.gimp.GIMP.flatpakref https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref
flatpak install https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref