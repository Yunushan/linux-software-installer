#!/bin/bash

#19-Mysql Router
mysql_community=$(lynx -dump https://dev.mysql.com/downloads/file/?id=508944 | awk '/http/{print $2}' | grep -i .rpm | head -n 1)
sudo wget -O /root/Downloads/mysql80-community-release.rpm "$mysql_community"
sudo rpm -Uvh mysql80-community-release.rpm
sudo dnf -vy install mysql-router