#!/bin/bash

#43-Zabbix Server
printf "\nPlease Choose Your Desired Zabbix Option\n\n1-)Zabbix Server 4.0 LTS (Mysql & Apache)\n\
2-)Zabbix Server 4.0 LTS (PostgreSQL & Apache)\n3-)Zabbix Server 5.0 LTS (Mysql & Apache)\n\
4-)Zabbix Server 5.0 LTS (Mysql & NGINX)\n5-)Zabbix Server 5.0 LTS (PostgreSQL & Apache)\n\
6-)Zabbix Server 5.0 LTS (PostgreSQL & NGINX)\n\nPlease Select Your Zabbix Option:"
read -r zabbix_option
if [ "$zabbix_option" = "1" ];then
    printf "Please Enter Desired Mysql Password:"
    read -r mysqlpassword
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/8/x86_64/zabbix-release-4.0-2.el8.noarch.rpm
    sudo dnf clean all
    sudo dnf -vy install zabbix-server-mysql zabbix-web-mysql zabbix-agent mysql mysql-devel mysql-server httpd httpd-devel
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$mysqlpassword';"
    sudo systemctl restart mysqld.service
    sudo mysql -uroot -p$mysqlpassword -e "create database zabbix character set utf8 collate utf8_bin;"
    sudo mysql -uroot -p$mysqlpassword -e "create user zabbix@localhost identified by '$mysqlpassword';"
    sudo mysql -uroot -p$mysqlpassword -e "grant all privileges on zabbix.* to zabbix@localhost;"
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$mysqlpassword zabbix
    sed -i "s/# DBPassword=/DBPassword=$mysqlpassword/g" /etc/zabbix/zabbix_server.conf
    echo "php_value[date.timezone] = UTC" >> /etc/php-fpm.d/zabbix.conf
    sudo systemctl restart zabbix-server zabbix-agent httpd
    sudo systemctl enable zabbix-server zabbix-agent httpd
elif [ "$zabbix_option" = "2" ];then
    printf "Please Enter Desired PostgreSQL Password:"
    read -r PGPASSWORD
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/8/x86_64/zabbix-release-4.0-2.el8.noarch.rpm
    dnf clean all
    sudo dnf -vy install postgresql postgresql-server postgresql-contrib
    sudo dnf -vy install zabbix-server-pgsql zabbix-web-pgsql zabbix-agent httpd httpd-devel
    sudo postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    echo "Please Enter Your Zabbix User Password"
    sudo -u postgres createuser --pwprompt zabbix
    sudo -u postgres createdb -O zabbix zabbix
    zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
    sed -i "s/DBPassword=/DBPassword=$PGPASSWORD/g" /etc/zabbix/zabbix_server.conf
    echo "php_value[date.timezone] = UTC" >> /etc/php-fpm.d/zabbix.conf
    systemctl restart zabbix-server zabbix-agent httpd php-fpm
    systemctl enable zabbix-server zabbix-agent httpd php-fpm
elif [ "$zabbix_option" = "3" ];then
    printf "Please Enter Desired Mysql Password:"
    read -r mysqlpassword
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    dnf clean all
    sudo dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent zabbix-apache-conf mysql \
    mysql-devel mysql-server httpd httpd-devel
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$mysqlpassword';"
    sudo systemctl restart mysqld.service
    sudo mysql -uroot -p$mysqlpassword -e "create database zabbix character set utf8 collate utf8_bin;"
    sudo mysql -uroot -p$mysqlpassword -e "create user zabbix@localhost identified by '$mysqlpassword';"
    sudo mysql -uroot -p$mysqlpassword -e "grant all privileges on zabbix.* to zabbix@localhost;"
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$mysqlpassword zabbix
    sed -i "s/# DBPassword=/DBPassword=$mysqlpassword/g" /etc/zabbix/zabbix_server.conf
    echo "php_value[date.timezone] = UTC" >> /etc/php-fpm.d/zabbix.conf
    sudo systemctl restart zabbix-server zabbix-agent httpd
    sudo systemctl enable zabbix-server zabbix-agent httpd
elif [ "$zabbix_option" = "4" ];then
    printf "Please Enter Desired Mysql Password:"
    read -r mysqlpassword
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    dnf clean all
    sudo dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-sql-scripts \
    zabbix-agent mysql mysql-devel mysql-server
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$mysqlpassword';"
    sudo systemctl restart mysqld.service
    sudo mysql -uroot -p$mysqlpassword -e "create database zabbix character set utf8 collate utf8_bin;"
    sudo mysql -uroot -p$mysqlpassword -e "create user zabbix@localhost identified by '$mysqlpassword';"
    sudo mysql -uroot -p$mysqlpassword -e "grant all privileges on zabbix.* to zabbix@localhost;"
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$mysqlpassword zabbix
    sed -i "s/# DBPassword=/DBPassword=$mysqlpassword/g" /etc/zabbix/zabbix_server.conf
    echo "php_value[date.timezone] = UTC" >> /etc/php-fpm.d/zabbix.conf
    sudo systemctl restart zabbix-server zabbix-agent httpd
    sudo systemctl enable zabbix-server zabbix-agent httpd
elif [ "$zabbix_option" = "5" ];then
    printf "Please Enter Desired PostgreSQL Password:"
    read -r PGPASSWORD
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    dnf clean all
    sudo dnf -vy install postgresql postgresql-server postgresql-contrib
    sudo dnf -vy install zabbix-server-pgsql zabbix-web-pgsql zabbix-agent httpd httpd-devel
    sudo postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    echo "Please Enter Your Zabbix User Password"
    sudo -u postgres createuser --pwprompt zabbix
    sudo -u postgres createdb -O zabbix zabbix
    zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
    sed -i "s/DBPassword=/DBPassword=$PGPASSWORD/g" /etc/zabbix/zabbix_server.conf
    echo "php_value[date.timezone] = UTC" >> /etc/php-fpm.d/zabbix.conf
    systemctl restart zabbix-server zabbix-agent httpd php-fpm
    systemctl enable zabbix-server zabbix-agent httpd php-fpm
elif [ "$zabbix_option" = "6" ];then
    printf "Please Enter Desired PostgreSQL Password:"
    read -r PGPASSWORD
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    dnf clean all
    sudo dnf -vy install postgresql postgresql-server postgresql-contrib
    sudo dnf -vy install zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent \
    mysql mysql-devel mysql-server
    sudo postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    echo "Please Enter Your Zabbix User Password"
    sudo -u postgres createuser --pwprompt zabbix
    sudo -u postgres createdb -O zabbix zabbix
    zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
    sed -i "s/DBPassword=/DBPassword=$PGPASSWORD/g" /etc/zabbix/zabbix_server.conf
    echo "php_value[date.timezone] = UTC" >> /etc/php-fpm.d/zabbix.conf
    systemctl restart zabbix-server zabbix-agent httpd php-fpm
    systemctl enable zabbix-server zabbix-agent httpd php-fpm
else
    echo "Out of options please choose between 1-6"
fi