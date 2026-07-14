#!/bin/bash

#44-UrBackup Server
printf "\nPlease Choose Your UrBackup Version \n\n1-)UrBackup Server (Official Package)\n\
2-)UrBackup Server (Docker)\n3-)UrBackup Server Latest (Compile From Source)\n\nPlease Select Your UrBackup Version:"
read -r urbackup_version
if [ "$urbackup_version" = "1" ];then
    cd /etc/yum.repos.d/
    wget https://download.opensuse.org/repositories/home:uroni/CentOS_8/home:uroni.repo
    sudo dnf -vy install urbackup-server
elif [ "$urbackup_version" = "2" ];then
    sudo dnf -vy install yum-utils
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    docker run -d --name urbackup-server-1 -v /media/backups:/backups -v /media/database:/var/urbackup -p \
    55413-55415:55413-55415 -p 35623:35623/udp uroni/urbackup-server
elif [ "$urbackup_version" = "3" ];then
    sudo dnf -vy install gcc gcc-c++ zlib zlib-devel libcurl libcurl-devel openssl-devel cryptopp-devel
    urbackup_latest=$(lynx -dump https://hndl.urbackup.org/Server/ | awk '/http/{print $2}' | grep -iv 'dev\|latest\|RC\|beta' \
    | tail -n 1)
    urbackup_latest=$(lynx -dump "$urbackup_latest" | awk '/http/{print $2}' | grep -i tar.gz | head -n 1)
    sudo mkdir -pv /root/Downloads/urbackup-server-latest
    wget -O /root/Downloads/urbackup-server-latest.tar.gz "$urbackup_latest"
    tar -xvf /root/Downloads/urbackup-server-latest.tar.gz -C /root/Downloads/urbackup-server-latest --strip-components 1
    cd /root/Downloads/urbackup-server-latest
    ./configure
    make -j "$core" && make -j "$core" install
    cp urbackup-server.service /etc/systemd/system/
    systemctl enable urbackup-server.service
    cp defaults_server /etc/default/urbackupsrv
    cp logrotate_urbackupsrv /etc/logrotate.d/urbackupsrv
    systemctl start urbackup-server
else
    echo "Out of options please choose between 1-3"
fi