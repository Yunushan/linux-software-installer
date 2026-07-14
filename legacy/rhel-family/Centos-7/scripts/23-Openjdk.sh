#!/bin/bash

#23-OpenJDK 8-11-17
printf "\nPlease Choose Your Desired OpenJDK Version\n\n1-)OpenJDK 6\n2-)OpenJDK 7\n3-)OpenJDK 8\n4-)OpenJDK 11\n5-)OpenJDK 17\n\nPlease Select Your OpenJDK Version:"
read -r openjdkversion
if [ "$openjdkversion" = "1" ];then
    sudo yum -y remove java*
    sudo rpm -e jdk-17
    sudo yum -y install java-1.6.0-openjdk java-1.6.0-openjdk-devel
elif [ "$openjdkversion" = "2" ];then
    sudo yum -y remove java*
    sudo rpm -e jdk-17
    sudo yum -y install java-1.7.0-openjdk java-1.7.0-openjdk-devel
elif [ "$openjdkversion" = "3" ];then
    sudo yum -y remove java*
    sudo rpm -e jdk-17
    sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
elif [ "$openjdkversion" = "4" ];then
    sudo yum -y remove java*
    sudo rpm -e jdk-17
    sudo yum -y install java-11-openjdk java-11-openjdk-devel
elif [ "$openjdkversion" = "5" ];then
    sudo yum -y remove java*
    sudo rpm -e jdk-17
    sudo wget -O /root/Downloads/jdk-17_linux-x64_bin.rpm https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm
    sudo rpm -ivh /root/Downloads/jdk-17_linux-x64_bin.rpm
else
    echo "Out of options please choose between 1-5"
fi