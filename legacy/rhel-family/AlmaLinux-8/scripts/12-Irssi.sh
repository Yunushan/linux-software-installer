#!/bin/bash

#12-Irssi (IRC)
printf "\nPlease Choose Your Desired Irssi Version\n\n1-)Irssi (From Official Repository) \n\
2-)Irssi (snap)(Newer version)\n\nPlease Select Your Irssi Version:"
read -r irssiversion
if [ "$irssiversion" = "1" ];then
    sudo dnf -vy install irssi
    printf "\nIrssi (From Official Repository) Installation Has Finished\n\n"
elif [ "$irssiversion" = "2" ];then
    sudo snap install irssi
    printf "\nIrssi (snap)(Newer version) Installation Has Finished\n\n"
fi