#!/bin/bash

#40-GoCD
printf "\nPlease Choose Your GoCD Version \n\n1-)GoCD Server\n2-)GoCD Server (Docker)\n\
3-)GoCD Agent\n4-)GoCD Agent (Docker)\n\nPlease Select Your GoCD Version:"
read -r gocd_version
if [ "$gocd_version" = "1" ];then
    sudo dnf -vy install java-1.8.0-openjdk-devel
    java -version
    sudo curl https://download.gocd.org/gocd.repo -o /etc/yum.repos.d/gocd.repo
    sudo dnf -vy install go-server
    sudo systemctl start go-server
    sudo systemctl enable go-server
    sudo mkdir -pv /opt/artifacts
    sudo chown -R go:go /opt/artifacts
elif [ "$gocd_version" = "2" ];then
    sudo dnf -vy install yum-utils procps
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    docker pull gocd/gocd-server
    docker run -d -p8153:8153 gocd/gocd-server:v21.4.0
elif [ "$gocd_version" = "3" ];then
    sudo curl https://download.gocd.org/gocd.repo -o /etc/yum.repos.d/gocd.repo
    sudo dnf -vy install go-agent
elif [ "$gocd_version" = "4" ];then
    sudo dnf -vy install yum-utils procps
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    docker pull gocd/gocd-agent-centos-7
else
    echo "Out of options please choose between 1-4"
fi