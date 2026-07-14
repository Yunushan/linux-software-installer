#!/bin/bash

#50-Enterprise Search
printf "\nPlease Choose Your Desired Enterprise Search Version\n\n1-) Enterprise Search 8.1.0 (From .rpm file)\n\
2-) Enterprise Search Latest (Via Docker)\n\nPlease Select Your Enterprise Search Version:"
read -r enterprise_search_version
if [ "$elasticsearch_version" = "1" ];then
    sudo dnf -vy rmeove java*
    sudo dnf -vy install java-11-openjdk-devel
    wget -O /root/Downloads/enterprise-search-8.1.0.rpm  \
    https://artifacts.elastic.co/downloads/enterprise-search/enterprise-search-8.1.0.rpm
    sudo rpm -Uvh /root/Downloads/enterprise-search-8.1.0.rpm
elif [ "$elasticsearch_version" = "2" ];then
    sudo dnf -vy rmeove java*
    sudo dnf -vy install java-11-openjdk-devel
    sudo dnf -vy install yum-utils
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    docker pull docker.elastic.co/enterprise-search/enterprise-search:8.1.0
elif [ "$elasticsearch_version" = "3" ];then
    sudo dnf -vy remove java*
    sudo dnf -vy install java-11-openjdk-devel
    sudo mkdir -pv /root/Downloads/enterprise-search-8.1.0
    wget -O /root/Downloads/enterprise-search-8.1.0.tar.gz \
    https://artifacts.elastic.co/downloads/enterprise-search/enterprise-search-8.1.0.tar.gz
    tar -xvf /root/Downloads/enterprise-search-8.1.0.tar.gz -C /root/Downloads/enterprise-search-8.1.0 --strip-components 1
    cd /root/Downloads/enterprise-search-8.1.0/bin/
    ./enterprise-search
else
    echo "Out of options please choose between 1-3"
fi