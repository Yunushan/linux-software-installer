#!/bin/bash

#41-Mariadb
printf "\nPlease Choose Your Desired Mariadb Version\n\n1-)Mariadb 10.3\n2-)Mariadb 10.4\n3-)Mariadb 10.5\n4-)Mariadb 10.6\n\nPlease Select Your Mariadb Version:"
read -r mariadbversion
if [ "$mariadbversion" = "1" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.3
    sudo dnf install boost-program-options -y
    sudo dnf module reset mariadb -y
    sudo yum -y remove mariadb-libs
    sudo yum -y remove mariadb mariadb-server galera*
    cd /var/lib/ && rm -rfv mysql
    sudo yum install mariadb mariadb-devel MariaDB-server MariaDB-client MariaDB-backup -y
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb
    systemctl status mariadb
elif [ "$mariadbversion" = "2" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.4
    sudo dnf install boost-program-options -y
    sudo dnf module reset mariadb -y
    sudo yum -y remove mariadb-libs
    sudo yum -y remove mariadb mariadb-server galera*
    cd /var/lib/ && rm -rfv mysql   
    sudo yum install mariadb mariadb-devel MariaDB-server MariaDB-client MariaDB-backup -y
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb
    systemctl status mariadb
elif [ "$mariadbversion" = "3" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.5
    sudo dnf install boost-program-options -y
    sudo dnf module reset mariadb -y
    sudo yum -y remove mariadb-libs
    sudo yum -y remove mariadb mariadb-server galera*
    cd /var/lib/ && rm -rfv mysql   
    sudo yum install mariadb mariadb-devel MariaDB-server MariaDB-client MariaDB-backup -y
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb
    systemctl status mariadb
elif [ "$mariadbversion" = "4" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.6
    sudo dnf install boost-program-options -y
    sudo dnf module reset mariadb -y
    sudo yum -y remove mariadb-libs
    sudo yum -y remove mariadb mariadb-server galera*
    cd /var/lib/ && rm -rfv mysql   
    sudo yum install mariadb mariadb-devel MariaDB-server MariaDB-client MariaDB-backup -y
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb
    systemctl status mariadb
else
    echo "Out of options please choose between 1-4"
fi