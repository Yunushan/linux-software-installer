#!/bin/bash

#29-Nodejs-And-Npm
printf "\nPlease Choose Your Desired Nodejs Version\n\n1-)Nodejs 10 (Official Repo)\n2-)Nodejs 12\n\
3-)Nodejs 14\n4-)Nodejs 16\n\nPlease Select Your Nodejs Version:"
read -r nodejsversion
if [ "$nodejsversion" = "1" ];then
    sudo dnf -vy remove nodejs
    sudo dnf -vy module disable nodejs:12
    sudo dnf -vy module disable nodejs:14
    sudo dnf -vy module disable nodejs:16
    sudo dnf -vy module enable nodejs:10
    sudo dnf -vy install nodejs
    node --version
elif [ "$nodejsversion" = "2" ];then
    sudo dnf -vy remove nodejs
    sudo dnf -vy module disable nodejs:10
    sudo dnf -vy module disable nodejs:14
    sudo dnf -vy module disable nodejs:16
    sudo dnf -vy module enable nodejs:12
    sudo dnf -vy install nodejs
    node --version
elif [ "$nodejsversion" = "3" ];then
    sudo dnf -vy remove nodejs 
    sudo dnf -vy module disable nodejs:10
    sudo dnf -vy module disable nodejs:12
    sudo dnf -vy module disable nodejs:16
    sudo dnf -vy module enable nodejs:14
    sudo dnf -vy install nodejs
    node --version
elif [ "$nodejsversion" = "4" ];then
    sudo dnf -vy remove nodejs
    sudo dnf -vy module disable nodejs:10
    sudo dnf -vy module disable nodejs:12
    sudo dnf -vy module disable nodejs:14
    sudo dnf -vy module enable nodejs:16
    sudo dnf -vy install nodejs
    node --version
else
    echo "Out of options please choose between 1-4"
fi