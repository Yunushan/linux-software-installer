#!/bin/bash

#44-Nfs Server

sudo dnf -vy install nfs-utils portmap
echo "/nfsshare <ip-address>(rw,sync,no_root_squash)" > /etc/exports
sudo systemctl restart nfs-server