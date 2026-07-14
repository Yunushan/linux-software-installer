#!/bin/bash

#37-Graylog
printf "\nPlease Choose Your Desired Graylog Version\n\n1-)Graylog (Official .rpm) \n\
2-)Graylog (Manual Repository Installation)\n3-)Graylog (Official Packages Without Elasticsearch)\n\
4-)Graylog (Official Packages With Elasticsearch)\n5-)Graylog (Via Docker)\n\
6-)Graylog (Via Snap)\n7-)Graylog (Compile From Source)\n\nPlease Select Your Graylog Version:"
read -r graylog_version
if [ "$graylog_version" = "1" ];then
    sudo rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-4.2-repository_latest.rpm
    sudo dnf -vy install graylog-server graylog-enterprise-plugins graylog-integrations-plugins \
    graylog-enterprise-integrations-plugins
    sudo systemctl start graylog-server
    sudo systemctl enable graylog-server
elif [ "$graylog_version" = "2" ];then
echo "[graylog]
name=graylog
baseurl=https://packages.graylog2.org/repo/el/stable/4.2/x86_64/
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-graylog" > /etc/yum.repos.d/graylog.repo
    sudo dnf -vy install graylog-server graylog-enterprise-plugins graylog-integrations-plugins \
    graylog-enterprise-integrations-plugins
    sudo systemctl start graylog-server
    sudo systemctl enable graylog-server
elif [ "$graylog_version" = "3" ];then
    printf "\nPlease Enter Your Desired Graylog Password"
    read -r graylog_password
    echo -n "$graylog_password" && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
    #OpenJDK 8-11-17 JDK
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
    fi
    sudo dnf -vy install pwgen
echo "[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" > /etc/yum.repos.d/mongodb-org.repo
    sudo dnf -vy install mongodb-org
    sudo systemctl daemon-reload
    sudo systemctl enable mongod.service
    sudo systemctl start mongod.service
    #sudo systemctl --type=service --state=active | grep mongod
    sudo rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-4.2-repository_latest.rpm
    sudo dnf -vy install graylog-server graylog-enterprise-plugins graylog-integrations-plugins \
    graylog-enterprise-integrations-plugins
    echo -n "$graylog_password" && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
    sudo systemctl daemon-reload
    sudo systemctl enable graylog-server.service
    sudo systemctl start graylog-server.service
elif [ "$graylog_version" = "4" ];then
    printf "\nPlease Enter Your Desired Graylog Password"
    read -r graylog_password
    sudo dnf -vy install pwgen
echo "[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" > /etc/yum.repos.d/mongodb-org.repo
    sudo dnf -vy install mongodb-org
    sudo systemctl daemon-reload
    sudo systemctl enable mongod.service
    sudo systemctl start mongod.service
    #sudo systemctl --type=service --state=active | grep mongod
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo "[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/oss-7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" > /etc/yum.repos.d/elasticsearch.repo
sudo dnf -vy install elasticsearch-oss
sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOT
cluster.name: graylog
action.auto_create_index: false
EOT
    sudo systemctl daemon-reload
    sudo systemctl enable elasticsearch.service
    sudo systemctl restart elasticsearch.service
    sudo rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-4.2-repository_latest.rpm
    sudo dnf -vy install graylog-server graylog-enterprise-plugins graylog-integrations-plugins \
    graylog-enterprise-integrations-plugins
    echo -n "$graylog_password" && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
    sudo systemctl daemon-reload
    sudo systemctl enable graylog-server.service
    sudo systemctl start graylog-server.service
elif [ "$graylog_version" = "5" ];then
    #Docker
    sudo dnf -vy install yum-utils
    sudo dnf -vy install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -vy install docker-ce --nobest docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    printf "\nDocker Installation Has Finished\n\n"
    docker pull graylog/graylog
    docker pull mongo
    docker pull docker.elastic.co/elasticsearch/elasticsearch:8.0.0-amd64
elif [ "$graylog_version" = "6" ];then
    sudo snap install graylog --channel=4/stable
elif [ "$graylog_version" = "7" ];then
    sudo mkdir -pv /root/Downloads/graylog-latest/
    graylog_latest=$(lynx -dump https://www.graylog.org/downloads-2 | awk '/http/{print $2}' \
    | grep -iv 'enterprise\|plugins' | grep -i .tgz | head -n 1)
    wget -O /root/Downloads/graylog-latest.tgz "$graylog_latest"
    tar -xvf /root/Downloads/graylog-latest.tgz -C /root/Downloads/graylog-latest --strip-components 1
    cd /root/Downloads/graylog-latest
    #OpenJDK 8-11-17 JDK
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
        sudo dnf -vy remove java-1.8.0-openjdk-devel
        sudo dnf -vy install java-11-openjdk-devel
        printf "\nOpenJDK 11 JDK Installation Has Finished \n\n"
    elif [ "$openjdkversion" = "3" ];then
        sudo dnf -vy remove java-1.8.0-openjdk-devel
        sudo dnf -vy remove java-11-openjdk-devel
        sudo dnf -vy install java-17-openjdk-devel
        printf "\nOpenJDK 17 JDK Installation Has Finished \n\n"
    else
        echo "Out of options please choose between 1-3"
    fi
    cd bin/$ ./graylogctl start
else
    echo "Out of options please choose between 1-7"
fi