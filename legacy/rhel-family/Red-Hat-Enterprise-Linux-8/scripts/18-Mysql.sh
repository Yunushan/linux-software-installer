#!/bin/bash

#18-Mysql
printf "\nPlease Choose Your Desired Mysql Version\n\n1-)Mysql 8.0\n2-)Mysql 5.7\n3-)Mysql 5.6\n\
4-)Mysql 5.5\n5-)Mysql 8 (Latest)\n\nPlease Select Your Mysql Version:"
read -r mysqlversion
if [ "$mysqlversion" = "1" ];then
    sudo dnf -vy remove @mysql
    sudo dnf -vy module reset mysql && sudo dnf -vy module disable mysql
    echo "" > /etc/yum.repos.d/mysql-community.repo
    sudo dnf config-manager --disable mysql57-community
    sudo dnf config-manager --disable mysql56-community
    sudo dnf config-manager --disable mysql55-community
    if ! command -v mysql &> /dev/null;then
        echo "Installing Mysql"
        sudo dnf -vy module enable mysql
        sudo dnf -vy install mysql-devel mysql-server
    else
        printf "\nDifferent Mysql Version Detected To Install Mysql You Must Uninstall Different Version First (y/n):"
        read -r mysql_uninstall_verify
        if [ "$mysql_uninstall_verify" = "Y" ] || [ "$mysql_uninstall_verify" = "y" ];then
            echo "Uninstalling mysql"
            sudo dnf -vy remove mysql-community-server mysql-devel mysql-server
        else
            :
        fi
    fi
    sudo dnf -vy module enable mysql
    sudo dnf -vy install mysql-devel mysql-server
    systemctl start mysqld
    systemctl enable mysqld
elif [ "$mysqlversion" = "2" ];then
    sudo dnf -vy remove @mysql
    sudo dnf -vy module reset mysql && sudo dnf -vy module disable mysql
echo "[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/$cpuarch/
enabled=1
gpgcheck=0

[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=http://repo.mysql.com/yum/mysql-connectors-community/el/7/$cpuarch/
enabled=1
gpgcheck=0

[mysql-tools-community]
name=MySQL Tools Community
baseurl=http://repo.mysql.com/yum/mysql-tools-community/el/7/$cpuarch/
enabled=1
gpgcheck=0" > /etc/yum.repos.d/mysql-community.repo
    if ! command -v mysql &> /dev/null;then
        echo "Installing Mysql"
        sudo dnf -vy module enable mysql
        sudo dnf -vy install mysql-community-server
    else
        printf "\nDifferent Mysql Version Detected To Install Mysql You Must Uninstall Different Version First (y/n):"
        read -r mysql_uninstall_verify
        if [ "$mysql_uninstall_verify" = "Y" ] || [ "$mysql_uninstall_verify" = "y" ];then
            echo "Uninstalling mysql"
            sudo dnf -vy remove mysql-community-server mysql-devel mysql-server
        else
            :
        fi
    fi
    sudo dnf -vy install mysql-community-server
    sudo dnf config-manager --disable mysql80-community
    sudo dnf config-manager --enable mysql57-community
    sudo dnf config-manager --disable mysql56-community
    sudo dnf config-manager --disable mysql55-community
    sudo dnf -vy install mysql-community-server
    systemctl enable --now mysqld.service
    sudo systemctl restart mysqld
    printf "\nMysql 5.7 Installation Has Finished.\n\n"
elif [ "$mysqlversion" = "3" ];then
    sudo dnf -vy remove @mysql 
    sudo dnf -vy module reset mysql && sudo dnf -vy module disable mysql
echo "# Enable to use MySQL 5.6
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/7/$cpuarch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql" > /etc/yum.repos.d/mysql-community.repo
    sudo dnf -vy module disable mysql
    sudo dnf config-manager --disable mysql80-community
    sudo dnf config-manager --disable mysql57-community
    sudo dnf config-manager --enable mysql56-community
    sudo dnf config-manager --disable mysql55-community
    if ! command -v mysql &> /dev/null;then
        echo "Installing Mysql"
        sudo dnf -vy install mysql-community-server
    else
        printf "\nDifferent Mysql Version Detected To Install Mysql You Must Uninstall Different Version First (y/n):"
        read -r mysql_uninstall_verify
        if [ "$mysql_uninstall_verify" = "Y" ] || [ "$mysql_uninstall_verify" = "y" ];then
            echo "Uninstalling mysql"
            sudo dnf -vy remove mysql-community-server mysql-devel mysql-server
        else
            :
        fi
    fi
    auditctl -w /etc/shadow -p w
    ausearch -m avc -ts recent
    ausearch -c 'mysqld_safe' --raw | audit2allow -O /root/ -M my-mysqldsafe
    semodule -X 300 -i my-mysqldsafe.pp
    sudo rm -f my-mysqldsafe.te my-mysqldsafe.pp
    sudo dnf -vy install mysql-community-server
    #systemctl start mysqld
    #systemctl enable mysqld
    printf "\nMysql 5.6 Installation Has Finished.\n\n"
elif [ "$mysqlversion" = "4" ];then
echo "# Enable to use MySQL 5.5
[mysql55-community]
name=MySQL 5.5 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.5-community/el/7/$cpuarch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql" > /etc/yum.repos.d/mysql-community.repo
    sudo dnf -vy module disable mysql
    sudo dnf config-manager --disable mysql80-community
    sudo dnf config-manager --disable mysql57-community
    sudo dnf config-manager --disable mysql56-community
    sudo dnf config-manager --enable mysql55-community
    if ! command -v mysql &> /dev/null;then
        echo "Installing Mysql"
        sudo dnf -vy install mysql-community-server
    else
        printf "\nDifferent Mysql Version Detected To Install Mysql You Must Uninstall Different Version First (y/n):"
        read -r mysql_uninstall_verify
        if [ "$mysql_uninstall_verify" = "Y" ] || [ "$mysql_uninstall_verify" = "y" ];then
            echo "Uninstalling mysql"
            sudo dnf -vy remove mysql-community-server mysql-devel mysql-server
            sudo dnf -vy install mysql-community-server
        else
            :
        fi
    fi
elif [ "$mysqlversion" = "5" ];then
    mysql_community_server=$(lynx -dump https://dev.mysql.com/downloads/file/?id=509898 | awk '/http/{print $2}' \
    | grep -i rpm | head -n 1)
    mysql_community_client=$(lynx -dump https://dev.mysql.com/downloads/file/?id=509895 | awk '/http/{print $2}' \
    | grep -i rpm | head -n 1)
    mysql_community_common=$(lynx -dump https://dev.mysql.com/downloads/file/?id=509896 | awk '/http/{print $2}' \
    | grep -i rpm | head -n 1)
    mysql_community_icu_data_files=$(lynx -dump https://dev.mysql.com/downloads/file/?id=509907 | awk '/http/{print $2}' \
    | grep -i rpm | head -n 1)
    sudo wget -O /root/Downloads/mysql-community-server-latest.rpm "$mysql_community_server"
    sudo wget -O /root/Downloads/mysql-community-client-latest.rpm "$mysql_community_client"
    sudo wget -O /root/Downloads/mysql-community-common-latest.rpm "$mysql_community_common"
    sudo wget -O /root/Downloads/mysql-community-icu-data-files-latest.rpm "$mysql_community_icu_data_files"
    sudo rpm -Uvh mysql-community*
    systemctl start mysqld
    systemctl enable mysqld
    printf "\nMysql 8 (Latest) Installation Has Finished.\n\n"
else
    echo "Out of options please choose between 1-5"
fi