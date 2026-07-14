#!/bin/bash

#1-PHP 7.1
sudo yum remove webtatic-release -y
sudo yum install https://centos6.iuscommunity.org/ius-release.rpm -y
sudo yum install php71u-cli php71u-common php71u-fpm php71u-gd php71u-mbstring php71u-mysqlnd php71u-opcache php71u-pdo php71u-pear php71u-pecl-igbinary php71u-pecl-imagick php71u-pecl-memcached php71u-process php71u-xml -y
printf "\nPhp 7.1 installation Has Finished\n\n"