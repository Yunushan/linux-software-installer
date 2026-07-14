#!/bin/bash

#27-Docker
sudo dnf -vy install yum-utils
sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
printf "\nDocker Installation Has Finished\n\n"