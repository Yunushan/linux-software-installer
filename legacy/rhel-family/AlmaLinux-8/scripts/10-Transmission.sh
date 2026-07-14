#!/bin/bash

#10-Transmission
sudo wget -O /root/Downloads/geekery-release-8-2.noarch.rpm \
http://geekery.altervista.org/geekery/el8/x86_64/geekery-release-8-2.noarch.rpm
sudo dnf -vy install /root/Downloads/geekery-release-8-2.noarch.rpm
sudo dnf -vy install transmission
sudo systemctl start transmission-daemon.service
printf "\nTransmission Installation Has Finished\n\n"