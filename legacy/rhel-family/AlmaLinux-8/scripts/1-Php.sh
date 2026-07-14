#!/bin/bash

#1-PHP
sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -vy install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf -vy install yum-utils 
printf "\nPlease Choose Your Desired PHP Version\n\n1-)PHP5.6\n2-)PHP7.0\n3-)PHP7.1\n4-)PHP7.2\n5-)PHP7.3\n\
6-)PHP7.4\n7-)PHP8.0\n8-)PHP8.1\n\nPlease Select Your PHP Version:"
read -r phpversion
if [ "$phpversion" = "1" ];then
    sudo dnf -vy module install php:remi-5.6
elif [ "$phpversion" = "2" ];then
    sudo dnf -vy module install php:remi-7.0
elif [ "$phpversion" = "3" ];then
    sudo dnf -vy module install php:remi-7.1
elif [ "$phpversion" = "4" ];then
    sudo dnf -vy module install php:remi-7.2
elif [ "$phpversion" = "5" ];then
    sudo dnf -vy module install php:remi-7.3
elif [ "$phpversion" = "6" ];then
    sudo dnf -vy module install php:remi-7.4
elif [ "$phpversion" = "7" ];then
    sudo dnf -vy module install php:remi-8.0
elif [ "$phpversion" = "8" ];then
    sudo dnf -vy module install php:remi-8.1
else
    echo "Out of options please choose between 1-8"
    :
    sudo dnf -vy install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo
fi
printf "\nPHP Installation Has Finished\n\n"