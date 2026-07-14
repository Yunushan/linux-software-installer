#!/bin/bash

#34-MongoDB
printf "\nPlease Choose Your Desired MongoDB Version\n\n1-)MongoDB Official Repo (Stable) \n\
2-)MongoDB (From Source)\n\nPlease Select Your MongoDB Version:"
read -r mongodb_version
if [ "$mongodb_version" = "1" ];then
echo "[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" > /etc/yum.repos.d/mongodb-org-5.0.repo
    sudo dnf -vy install mongodb-org mongodb-org-database mongodb-database-tools mongodb-org-server mongodb-org-shell \
    mongodb-org-mongos mongodb-org-tools mongodb-mongosh mongodb-org-database-tools-extra checkpolicy
    sudo systemctl start mongod
    sudo systemctl enable mongod

elif [ "$mongodb_version" = "2" ];then
    sudo dnf -vy remove mongodb-org mongodb-org-database mongodb-database-tools mongodb-org-server mongodb-org-shell \
    mongodb-org-mongos mongodb-org-tools mongodb-mongosh mongodb-org-database-tools-extra checkpolicy
    sudo dnf -vy install libcurl openssl xz-libs
    mongodb_latest=$(lynx -dump https://www.mongodb.com/download-center/community/releases |  awk '/http/{print $2}' \
    | grep -i rhel80 | grep -i .tgz | head -n 1)
    sudo wget -O /root/Downloads/mongodb-latest.tar.gz "$mongodb_latest"
    sudo mkdir -pv /root/Downloads/mongodb-latest
    tar xzvf /root/Downloads/mongodb-latest.tar.gz -C /root/Downloads/mongodb-latest --strip-components 1
    cd /root/Downloads/mongodb-latest
    sudo cp /root/Downloads/mongodb-latest/bin/* /usr/local/bin/
    sudo ln -s /root/Downloads/mongodb-latest/bin/* /usr/local/bin/
echo "[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" > /etc/yum.repos.d/mongodb-org-5.0.repo
    sudo dnf -vy install mongodb-mongosh
    sudo mkdir -pv /var/lib/mongo
    sudo mkdir -pv /var/log/mongodb
    sudo chown -R mongod:mongod /var/lib/mongo
    sudo chown -R mongod:mongod /var/log/mongodb
    sudo dnf -vy install checkpolicy
    mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork
    mongosh
else
    echo "Out of options please choose between 1-2"
fi