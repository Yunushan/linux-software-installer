#!/bin/bash

#18-Neofetch
sudo dnf -vy install dnf-plugins-core
curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo \
https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
sudo dnf -vy install neofetch
printf "\nNeofetch Installation Has Finished\n\n"