#!/bin/bash

#6-Cmake
printf "\nPlease Choose Your Desired Installation Version\n\n1-)Cmake (From Official Repository) \n\
2-)Cmake (snap)(Newer version)\n\nPlease Select Your Cmake Version:"
read -r cmakeversion
if [ "$cmakeversion" = "1" ];then
    sudo dnf -vy install cmake 
    printf "\nCmake Installation Has Finished\n\n"
elif [ "$cmakeversion" = "2" ];then
    sudo snap install cmake --classic
    printf "\nCmake Installation Has Finished\n\n"
fi