#!/bin/bash

#51-Logstash
printf "\nPlease Choose Your Desired Logstash Version\n\n1-) Logstash (From Official Package)\n\
2-) Logstash (Via Docker)\n3-) Logstash (From .rpm file)\nPlease Select Your Logstash Version:"
read -r logstash_version
if [ "$logstash_version" = "1" ];then
    sudo dnf -vy rmeove java*
    sudo dnf -vy install java-11-openjdk-devel
    sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    echo "[logstash-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" > /etc/yum.repos.d/logstash.repo
    sudo dnf -vy install logstash
    sudo systemctl daemon-reload
    sudo systemctl start logstash
    sudo systemctl enable logstash
elif [ "$logstash_version" = "2" ];then
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
    docker pull docker.elastic.co/logstash/logstash:8.1.0
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"\
    -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
elif [ "$logstash_version" = "3" ];then
    sudo dnf -vy rmeove java*
    sudo dnf -vy install java-11-openjdk-devel
    sudo rpm -Uvh https://artifacts.elastic.co/downloads/logstash/logstash-8.1.0-x86_64.rpm
    sudo systemctl restart logstash
    sudo systemctl enable logtash
elif [ "$logstash_version" = "4" ];then
    sudo mkdir -pv /root/Downloads/logstash
    sudo dnf -vy rmeove java*
    sudo dnf -vy install java-11-openjdk-devel
    wget -O /root/Downloads/logstash-8.1.0-linux-x86_64.tar.gz \
    https://artifacts.elastic.co/downloads/logstash/logstash-8.1.0-linux-x86_64.tar.gz
    tar -xvf /root/Downloads/logstash-8.1.0-linux-x86_64.tar.gz -C /root/Downloads/logstash --strip-components 1
    echo "Installation completed, folder under /root/Downloads/logstash/"
else
    echo "Out of options please choose between 1-3"
fi