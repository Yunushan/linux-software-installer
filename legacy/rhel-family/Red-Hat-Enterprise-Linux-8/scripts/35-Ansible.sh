#!/bin/bash

#35-Ansible
printf "\nPlease Choose Your Desired Ansible Version\n\n1-)Ansible (From pip) \n\
2-)Ansible (From Official Package Manager)\n\nPlease Select Your Ansible Version:"
read -r ansible_version

if [ "$ansible_version" = "1" ];then
    sudo dnf -vy remove ansible
    sudo dnf -vy python39 python39-devel
    pip3.9 install ansible
elif [ "$ansible_version" = "2" ];then
    pip3.9 uninstall ansible -y
    sudo dnf -vy install ansible
else
    echo "Out of options please choose between 1-2"
fi