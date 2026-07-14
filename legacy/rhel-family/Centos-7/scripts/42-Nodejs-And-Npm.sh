#!/bin/bash

#42-Nodejs & Npm
printf "\nPlease Choose Your Desired Nodejs Version\n\n1-)Nodejs 10 (LTS)\n2-)Nodejs 12 (LTS)\n3-)Nodejs 14 (LTS)\n4-)Nodejs 16 (LTS)\n5-)Nodejs Latest\n6-)Nodejs Latest (LTS)\n\nPlease Select Your Nodejs Version:"
read -r nodejsversion
if [ "$nodejsversion" = "1" ];then
    sudo yum remove -y node*
    sudo yum install -y gcc-c++ make
    curl -fsSL https://rpm.nodesource.com/setup_10.x | bash -
    sudo rm -fr /var/cache/yum/*
    sudo yum clean all    
    sudo yum install -y nodejs
elif [ "$nodejsversion" = "2" ];then
    sudo yum remove -y node*
    sudo yum install -y gcc-c++ make
    sudo curl -fsSL https://rpm.nodesource.com/setup_12.x | bash -
    sudo rm -fr /var/cache/yum/*
    yum clean all    
    sudo yum install -y nodejs
elif [ "$nodejsversion" = "3" ];then
    sudo yum remove -y node*
    sudo yum install -y gcc-c++ make
    sudo curl -fsSL https://rpm.nodesource.com/setup_14.x | bash -
    sudo rm -fr /var/cache/yum/*
    yum clean all    
    sudo yum install -y nodejs
elif [ "$nodejsversion" = "4" ];then
    sudo yum remove -y node*
    sudo yum install -y gcc-c++ make
    curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
    sudo rm -fr /var/cache/yum/*
    sudo yum clean all
    sudo yum install -y nodejs
elif [ "$nodejsversion" = "5" ];then
    sudo yum remove -y node*
    sudo yum install -y gcc-c++ make
    curl -fsSL https://rpm.nodesource.com/setup_current.x | bash -
    sudo rm -fr /var/cache/yum/*
    sudo yum clean all    
    sudo yum install -y nodejs
elif [ "$nodejsversion" = "6" ];then
    sudo yum remove -y node*
    sudo yum install -y gcc-c++ make
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
    sudo rm -fr /var/cache/yum/*
    sudo yum clean all    
    sudo yum install -y nodejs
else
    echo "Out of options please choose between 1-6"  
fi