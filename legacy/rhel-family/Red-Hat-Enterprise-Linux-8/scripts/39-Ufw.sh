#!/bin/bash

#39-UFW
printf "\nPlease Choose Your Desired UFW Version\n1-)UFW(From Official Package)\n2-)UFW (Via Snap)\
\nPlease Select Your UFW Version:"
read -r ufw_version
if [ "$ufw_version" = "1" ];then
    sudo snap remove ufw
    sudo dnf -vy install ufw
    sudo systemctl start ufw
    sudo systemctl enable ufw
elif [ "$ufw_version" = "2" ];then
    sudo dnf -vy remove ufw
    sudo snap ufw
else
    echo "Out of options please choose between 1-2"
fi