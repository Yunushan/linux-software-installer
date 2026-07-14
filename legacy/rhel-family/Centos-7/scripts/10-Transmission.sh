#!/bin/bash

#10-Transmission-cli
sudo yum install transmission-cli transmission-common transmission-daemon -y
sudo systemctl enable transmission-daemon
sudo systemctl start transmission-daemon
sudo firewall-cmd --permanent --zone=public --add-port=9091/tcp
sudo firewall-cmd --reload