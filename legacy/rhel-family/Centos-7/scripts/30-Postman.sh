#!/bin/bash

#30-Postman
sudo yum install epel-release -y
sudo yum install snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sleep 2
sudo snap install postman