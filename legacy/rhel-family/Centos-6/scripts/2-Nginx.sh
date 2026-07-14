#!/bin/bash

#2-Nginx 
sudo wget -O /root/Downloads/TempDL/nginx-release-centos-6-0.el6.ngx.noarch.rpm http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
sudo rpm -ivh /root/Downloads/TempDL/nginx-release-centos-6-0.el6.ngx.noarch.rpm
sudo yum install nginx -y 
sudo chkconfig nginx on
sudo service nginx start
sudo echo "-A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT" >> /etc/sysconfig/iptables
sudo service iptables restart
printf "\nNginx installation Has Finished\n\n"