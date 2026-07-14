#!/bin/bash

#32-OpenNebula
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
cat /etc/selinux/config
sudo tee /etc/yum.repos.d/opennebula.repo<< EOT
[opennebula]
name=opennebula
baseurl=https://downloads.opennebula.org/repo/6.2/CentOS/8/x86_64
enabled=1
gpgkey=https://downloads.opennebula.org/repo/repo.key
gpgcheck=1
EOT
printf "\nPlease Choose Your Desired Database Version\n\n1-)Mysql\n2-)MariaDB\n3-)PostgreSQL\n\nPlease Select Your Database Version:"
read -r database_option
if [ "$database_option" = "1" ];then
    #Mysql Installation Selection
    printf "\nPlease Choose Your Desired Mysql Version\n\n1-)Mysql 8.0\n2-)Mysql 5.7\n3-)Mysql 5.6\n\
    4-)Mysql 5.5\n6-)Mysql 8 (Latest)\n\nPlease Select Your Mysql Version:"
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
elif [ "$database_option" = "2" ];then
    #MariaDB
printf "\nPlease Choose Your Desired MariaDB Version\n\n1-)MariaDB 10.3 (Official Repo)\n2-)MariaDB 10.4
3-)MariaDB 10.5\n4-)MariaDB 10.6\n\nPlease Select Your MariaDB Version:"
    read -r mariadbversion
    if [ "$mariadbversion" = "1" ];then
        wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
        bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.3
        sudo dnf -vy install boost-program-options
        sudo dnf -vy module reset mariadb
        sudo dnf -vy install mariadb mariadb-devel MariaDB-server MariaDB-client MariaDB-backup
        sudo systemctl enable --now mariadb
        sudo systemctl start mariadb
    elif [ "$mariadbversion" = "2" ];then
        wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
        sudo bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.4
        sudo dnf -vy install boost-program-options
        sudo dnf -vy module reset mariadb
        sudo dnf -vy install MariaDB-server MariaDB-client MariaDB-backup
        sudo systemctl enable --now mariadb
        sudo systemctl start mariadb
    elif [ "$mariadbversion" = "3" ];then
        wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
        sudo bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.5
        sudo dnf -vy install boost-program-options
        sudo dnf -vy module reset mariadb
        sudo dnf -vy install MariaDB-server MariaDB-client MariaDB-backup
        sudo systemctl enable --now mariadb
        sudo systemctl start mariadb
    elif [ "$mariadbversion" = "4" ];then
        wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
        sudo bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.6
        sudo dnf -vy install boost-program-options
        sudo dnf -vy module reset mariadb
        sudo dnf -vy install MariaDB-server MariaDB-client MariaDB-backup
        sudo systemctl enable --now mariadb
        sudo systemctl start mariadb 
    else
        echo "Out of options please choose between 1-4"
    fi
elif [ "$database_option" = "3" ];then
    printf "\nPlease Choose Your Desired PostgreSQL Version\n\n1-)PostgreSQL 9.6\n2-)PostgreSQL 10\n3-)PostgreSQL 11
4-)PostgreSQL 12\n5-)PostgreSQL 13\n6-)PostgreSQL 14\n\nPlease Select Your PostgreSQL Version:"
    read -r postgresql_version
    sudo dnf -vy install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    sudo dnf -vy module disable postgresql
    sudo dnf clean all
    if [ "$postgresql_version" = "1" ];then
        sudo dnf -y install postgresql96-server postgresql96
        sudo /usr/pgsql-96/bin/postgresql-96-setup initdb
        sudo systemctl enable postgresql-96
        sudo systemctl start postgresql-96
    elif [ "$postgresql_version" = "2" ];then
        sudo dnf -y install postgresql10-server postgresql10
        sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
        sudo systemctl enable postgresql-10
        sudo systemctl start postgresql-10
    elif [ "$postgresql_version" = "3" ];then
        sudo dnf -y install postgresql11-server postgresql11
        sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
        sudo systemctl enable postgresql-11
        sudo systemctl start postgresql-11
    elif [ "$postgresql_version" = "4" ];then
        sudo dnf -y install postgresql12-server postgresql12
        sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
        sudo systemctl enable postgresql-12
        sudo systemctl start postgresql-12
    elif [ "$postgresql_version" = "5" ];then
        sudo dnf -y install postgresql13-server postgresql13
        sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
        sudo systemctl enable postgresql-13
        sudo systemctl start postgresql-13
    elif [ "$postgresql_version" = "6" ];then
        sudo dnf -y install postgresql14-server postgresql14
        sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
        sudo systemctl enable postgresql-14
        sudo systemctl start postgresql-14
    else
        echo "Out of options please choose between 1-6"
    fi
else
    echo "Out of options please choose between 1-3"
fi
printf "\nPlease Enter Your Database Passoword:"
read -r database_password
mysql -u root -e "CREATE DATABASE opennebula;"
mysql -u root -e "CREATE USER 'oneadmin'@'localhost' IDENTIFIED BY '$database_password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'oneadmin'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
#sed -i '69,70 s/^/#/' /etc/one/oned.conf
#sed -i '73,80 s/^##*//' /etc/one/oned.conf
sudo dnf -vy install vim opennebula opennebula-server opennebula-sunstone  opennebula-gate opennebula-flow
sudo firewall-cmd --add-port=9869/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl start opennebula opennebula-sunstone
sudo systemctl enable opennebula opennebula-sunstone
#sudo su - oneadmin -c "oneuser show"