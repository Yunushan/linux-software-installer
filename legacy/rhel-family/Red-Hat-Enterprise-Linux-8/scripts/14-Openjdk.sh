#!/bin/bash

#14-OpenJDK 8-11-17 JDK
printf "\nPlease Choose Your Desired OpenJDK Version\n\n1-)OpenJDK 8 \n2-)OpenJDK 11\n\
3-)OpenJDK 17\n\nPlease Select Your OpenJDK Version:"
read -r openjdkversion
if [ "$openjdkversion" = "1" ];then
    sudo dnf -vy remove java-11-openjdk-devel
    sudo dnf -vy remove java-17-openjdk-devel
    sudo dnf -vy install java-1.8.0-openjdk-devel
    printf "\nOpenJDK 8 JDK Installation Has Finished \n\n"
elif [ "$openjdkversion" = "2" ];then
    sudo dnf -vy remove java-17-openjdk-devel
    sudo dnf -vy remove  java-1.8.0-openjdk-devel
    sudo dnf -vy install java-11-openjdk-devel
    printf "\nOpenJDK 11 JDK Installation Has Finished \n\n"
elif [ "$openjdkversion" = "3" ];then
    sudo dnf -vy remove  java-1.8.0-openjdk-devel
    sudo dnf -vy remove java-11-openjdk-devel
    sudo dnf -vy install java-17-openjdk-devel
    printf "\nOpenJDK 17 JDK Installation Has Finished \n\n"
else
    echo "Out of options please choose between 1-3"
    :
fi