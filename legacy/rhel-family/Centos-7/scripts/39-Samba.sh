#!/bin/bash

#39-Samba
sudo yum install samba samba-client samba-common -y
firewall-cmd --permanent --zone=public --add-service=samba
firewall-cmd --reload
sudo systemctl enable smb.service
sudo systemctl start smb.service
systemctl status smb.service