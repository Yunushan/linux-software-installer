#!/bin/bash

#1-PHP 5.4 - 8.1
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
sudo yum install yum-utils -y
printf "\nPlease Choose Your Desired PHP Version\n\n1-)PHP5.4\n2-)PHP5.5\n3-)PHP5.6\n4-)PHP7.0\n5-)PHP7.1\n6-)PHP7.2\n7-)PHP7.3\n8-)PHP7.4\n9-)PHP8.0\n10-)PHP8.1\n\nPlease Select Your PHP Version:"
read -r phpversion
if [ "$phpversion" = "1" ];then
    sudo yum-config-manager --enable remi-php54
elif [ "$phpversion" = "2" ];then
    sudo yum-config-manager --enable remi-php55
elif [ "$phpversion" = "3" ];then
    sudo yum-config-manager --enable remi-php56
elif [ "$phpversion" = "4" ];then
    sudo yum-config-manager --enable remi-php70
elif [ "$phpversion" = "5" ];then
    sudo yum-config-manager --enable remi-php71
elif [ "$phpversion" = "6" ];then
    sudo yum-config-manager --enable remi-php72
elif [ "$phpversion" = "7" ];then
    sudo yum-config-manager --enable remi-php73
elif [ "$phpversion" = "8" ];then
    sudo yum-config-manager --enable remi-php74
elif [ "$phpversion" = "9" ];then
    sudo yum-config-manager --enable remi-php80
elif [ "$phpversion" = "10" ];then
    sudo yum-config-manager --enable remi-php81
else
    echo "Out of option Please Choose between 1-10"
fi
sudo yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo -y
printf "\nPHP installation Has Finished\n\n"