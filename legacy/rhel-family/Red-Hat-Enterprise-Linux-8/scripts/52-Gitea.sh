#!/bin/bash

#52-Gitea
printf "\nPlease Choose Your Desired Gitea Version\n\n1-) Gitea (Install from binary)\n\
2-) Gitea (Install via snap)\n3-) Gitea (Via Docker)\n\nPlease Select Your Gitea Version:"
read -r gitea_version
if [ "$gitea_version" = "1" ];then
    gitea_stable_link=$(lynx -dump https://dl.gitea.io/gitea/ | awk '/http/ {print $2}' | grep -iv "rc\|dev\|.json" \
    | grep -i "gitea/" | head -n 1)
    gitea_stable_link=$(lynx -dump "$gitea_stable_link" | awk '/http/ {print $2}' | grep -iv ".exe\|sha\|asc\|darwin\|xz" \
    | grep -i linux-amd64 |  head -n 1)
    sudo mkdir -pv /root/Downloads/gitea
    wget -O /root/Downloads/gitea/gitea-stable-linux-amd64 "$gitea_stable_link"
    sudo chmod +x /root/Downloads/gitea/gitea-stable-linux-amd64
    sudo dnf -vy install git
    sudo useradd \
    --system \
    --shell /bin/bash \
    --comment 'Git Version Control' \
    --create-home \
    --home /home/git \
    git
    sudo mv -v /root/Downloads/gitea/gitea-stable-linux-amd64 /usr/local/bin/gitea
    mkdir -p /var/lib/gitea/{custom,data,log}
    chown -R git:git /var/lib/gitea/
    chmod -R 750 /var/lib/gitea/
    mkdir /etc/gitea
    chown root:git /etc/gitea
    chmod 770 /etc/gitea
    sudo wget https://raw.githubusercontent.com/go-gitea/gitea/master/contrib/systemd/gitea.service -P /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now gitea
    sudo systemctl start gitea
    sudo dnf -vy install nginx
    echo "server {
    listen 80;
    server_name gitea;

    location / {
        proxy_pass http://localhost:3000;
    }
}" > /etc/nginx/conf.d/gitea.conf
    sudo systemctl restart nginx
elif [ "$gitea_version" = "2" ];then
    sudo snap install gitea
elif [ "$gitea_version" = "3" ];then
    #Docker
    sudo dnf -vy install yum-utils
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    sudo mkdir -pv /root/gitea/
    echo "version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"" > /root/gitea/docker-compose.yml

else
    echo "Out of options please choose between 1-3"
fi