#!/bin/bash

#46-Kibana
printf "\nPlease Choose Your Desired Kibana Version\n\n1-) Kibana(From Official Package)\n\
2-) Kibana (Docker)\n\nPlease Select Your Kibana Version:"
read -r kibana_version
if [ "$kibana_version" = "1" ];then
    sudo dnf -vy rmeove java*
    sudo dnf -vy install java-11-openjdk-devel
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    sudo tee /etc/yum.repos.d/kibana.repo << EOT
[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOT
    sudo dnf -vy install kibana
    sudo systemctl daemon-reload
    sudo systemctl enable kibana
    sudo systemctl start kibana
elif [ "$kibana_version" = "2" ];then
    ## Install Docker ##
    sudo dnf -vy install yum-utils java-1.8.0-openjdk java-1.8.0-openjdk-devel
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    ## Install Docker ##
    docker network create elastic
    docker pull docker.elastic.co/elasticsearch/elasticsearch:8.1.0
    sudo mkdir -pv /root/Downloads/elasticsearch-docker
    sudo touch /root/Downloads/elasticsearch-docker/docker-compose.yml
    echo "version: '3'
services:
  elasticsearch:
    image: elasticsearch:8.1.0
    ports:
      - 9200:9200
    environment:
      discovery.type: 'single-node'
      xpack.security.enabled: 'false'" > /root/Downloads/elasticsearch-docker/docker-compose.yml
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"\
    -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    cd /root/Downloads/elasticsearch-docker
    docker-compose up -d
    sleep 15
    docker pull docker.elastic.co/kibana/kibana:8.1.0
    docker run -d --name kib-01 --net elastic -p 5601:5601 docker.elastic.co/kibana/kibana:8.1.0
    sleep 15
else
    echo "Out of options please choose between 1-2"
fi