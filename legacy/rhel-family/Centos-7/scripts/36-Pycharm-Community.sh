#!/bin/bash

#36-PyCharm Community Edition
sudo yum install epel-release -y
sudo yum install snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sleep 2
sudo snap install pycharm-community --classic