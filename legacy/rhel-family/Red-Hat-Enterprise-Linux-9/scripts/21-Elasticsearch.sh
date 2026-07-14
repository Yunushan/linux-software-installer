#!/bin/bash

#21-Elasticsearch
printf "\nPlease Choose Your Desired Elasticsearch Version\n\n1-) Elasticsearch(From Official Package)\n\
2-) Elasticsearch (Docker)\n\nPlease Select Your Elasticsearch Version:"
read -r elasticsearch_version
if [ "$elasticsearch_version" = "1" ];then
    sudo dnf -vy remove java*
    sudo dnf -vy install java-11-openjdk-devel
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo tee /etc/yum.repos.d/elasticsearch.repo << EOT
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOT
    sudo dnf -vy install --enablerepo=elasticsearch elasticsearch
    sudo sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/g' /etc/elasticsearch/elasticsearch.yml
    sudo systemctl daemon-reload
    sudo systemctl enable elasticsearch
    sudo systemctl restart elasticsearch
elif [ "$elasticsearch_version" = "2" ];then
    ## Install Docker##
    sudo dnf -vy remove java*
    sudo dnf -vy install java-11-openjdk-devel
    sudo dnf -vy install yum-utils
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    ## Install Docker##
    docker pull docker.elastic.co/elasticsearch/elasticsearch:8.3.2
    docker network create elastic
    #docker run -d --name es01 --net elastic -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -it docker.elastic.co/elasticsearch/elasticsearch:8.3.2
    #docker cp es01:/usr/share/elasticsearch/config/certs/http_ca.crt .
    #curl --cacert http_ca.crt -u elastic https://localhost:9200
    sudo mkdir -pv /root/Downloads/elasticsearch-docker
    sudo touch /root/Downloads/elasticsearch-docker/docker-compose.yml
    echo "version: '3'
services:
  elasticsearch:
    image: elasticsearch:8.3.2
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
    sleep 10
else
    echo "Out of options please choose between 1-2"
fi