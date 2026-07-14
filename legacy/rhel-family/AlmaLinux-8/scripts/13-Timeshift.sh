#!/bin/bash

#13-Timeshift
sudo dnf -vy install cairo-gobject gtk3 libgee gnutls vte291
wget -O /root/Downloads/timeshift-20.03-1.el7.x86_64.rpm \
https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/t/timeshift-20.03-1.el7.x86_64.rpm
sudo rpm -ivh /root/Downloads/timeshift-20.03-1.el7.x86_64.rpm
sudo dnf -vy install timeshift
printf "\nTimeshift Installation Has Finished\n\n"