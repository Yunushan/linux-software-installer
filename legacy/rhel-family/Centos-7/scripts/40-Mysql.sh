#!/bin/bash

#40-Mysql
printf "\nPlease Choose Your Desired Mysql Version\n\n1-)Mysql 8.0\n2-)Mysql 5.7\n3-)Mysql 5.6\n4-)Mysql 5.5\n\nPlease Select Your Mysql Version:"
read -r mysqlversion
if [ "$mysqlversion" = "1" ];then
    sudo dnf remove @mysql -y
    sudo dnf module reset mysql -y && sudo dnf module disable mysql -y
    sudo yum -y erase mysql*
    sudo yum remove mysql-community-server mysql-devel mysql-server -y
    sudo yum -y remove mysql-community-release*
    sudo yum-config-manager --disable mysql57-community
    sudo yum-config-manager --disable mysql56-community
    sudo yum-config-manager --disable mysql55-community
    sudo yum -y install https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
    sudo yum -y --enablerepo=mysql80-community install mysql-community-server
    sudo yum -y install mysql-community-server
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    systemctl status mysqld.service
elif [ "$mysqlversion" = "2" ];then
    sudo yum -y remove mysql-community-server mysql-devel mysql-server
    sudo yum -y erase mysql*
    sudo yum -y install https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
    sudo yum-config-manager --disable mysql80-community
    sudo yum-config-manager --disable mysql56-community
    sudo yum-config-manager --disable mysql55-community
    sudo yum --enablerepo=mysql57-community install mysql-community-server
    sudo yum -y install mysql-community-server
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    systemctl status mysqld.service
elif [ "$mysqlversion" = "3" ];then
    sudo yum remove mysql-community-server mysql-devel mysql-server -y
    sudo yum -y erase mysql*
    sudo rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
    sudo yum-config-manager --disable mysql80-community
    sudo yum-config-manager --disable mysql57-community
    sudo yum-config-manager --disable mysql55-community
    sudo yum --enablerepo=mysql56-community install mysql-community-server
    sudo yum -y install mysql-community-server
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    systemctl status mysqld.service
elif [ "$mysqlversion" = "4" ];then
    sudo yum -y remove mysql-community-server mysql-devel mysql-server
    sudo yum -y erase mysql*
    sudo yum install -y http://repo.mysql.com/yum/mysql-5.5-community/el/7/x86_64/mysql-community-release-el7-5.noarch.rpm
    sudo yum-config-manager --disable mysql80-community
    sudo yum-config-manager --disable mysql57-community
    sudo yum-config-manager --disable mysql55-community
    sudo yum -y --enablerepo=mysql55-community install mysql-community-server
    sudo yum -y install mysql-community-server
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    systemctl status mysqld.service
else
    echo "Out of options please choose between 1-5"
fi
#sudo yum update kernel -y # To Update Linux Kernel
printf "\nMysql Installation Has Finished.\n\n"