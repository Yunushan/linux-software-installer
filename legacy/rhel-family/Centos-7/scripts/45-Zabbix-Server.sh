#!/bin/bash

#45-Zabbix Server
printf "\nPlease Choose Your Desired Zabbix Option\n\n1-)Zabbix Server 4.0 LTS (Mysql & Apache)\n\
2-)Zabbix Server 4.0 LTS (PostgreSQL & Apache)\n3-)Zabbix Server 5.0 LTS (Mysql & Apache)\n\
4-)Zabbix Server 5.0 LTS (Mysql & NGINX)\n5-)Zabbix Server 5.0 LTS (PostgreSQL & Apache)\n\
6-)Zabbix Server 5.0 LTS (PostgreSQL & NGINX)\n\nPlease Select Your Zabbix Option:"
read -r zabbix_option
printf "Please Enter Desired Mysql/PostgreSQL Password:"
read -sr dbpassword
if [ "$zabbix_option" = "1" ];then
    sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
    sudo yum clean all
    sudo yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent
    sudo mysql -uroot -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '12345';"
    sudo systemctl restart mysql.service
    sudo mysql -uroot -p -e "create database zabbix character set utf8 collate utf8_bin;"
    sudo mysql -uroot -p -e "create user zabbix@localhost identified by 'password';"
    sudo mysql -uroot -p -e "grant all privileges on zabbix.* to zabbix@localhost;"
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
    sed -i "s/DBPassword=/DBPassword=$dbpassword/g" /etc/zabbix/zabbix_server.conf
    sed -i 's/# php_value date.timezone Europe/Riga/php_value date.timezone UTC/g' /etc/httpd/conf.d/zabbix.conf
    phpconf_date_timezone=$(cat /etc/httpd/conf.d/zabbix.conf | grep -i "php_value date.timezone" | head -n 1)
    sed -i "s/$phpconf_date_timezone/php_value date.timezone UTC/g"
    sudo systemctl restart zabbix-server zabbix-agent httpd
    sudo systemctl enable zabbix-server zabbix-agent httpd
elif [ "$zabbix_option" = "2" ];then
    echo "test"
elif [ "$zabbix_option" = "3" ];then
    echo "test"
elif [ "$zabbix_option" = "4" ];then
    echo "test"
elif [ "$zabbix_option" = "5" ];then
    echo "test"
elif [ "$zabbix_option" = "6" ];then
    echo "test"
else
    echo "Out of options please choose between 1-6"
fi