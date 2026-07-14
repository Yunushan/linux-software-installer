#!/bin/bash

#18-Neofetch
sudo yum install epel-release dnf -y
curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
sudo dnf install neofetch -y