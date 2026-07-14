#!/bin/bash

#1-PHP 7.2 - 8.1
sudo dnf -vy install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
printf "\nPlease Choose Your Desired PHP Version\n\n1-)PHP 7.2\n2-)PHP 7.3\n3-)PHP 7.4\n4-)PHP 8.0\n5-)PHP 8.1\
\n\nPlease Select Your PHP Version:"
read -r phpversion
if [ "$phpversion" = "1" ];then
    sudo dnf -vy module enable php:remi-7.2
    sudo dnf -vy install php php-cli php-common php-fpm php-mysqlnd php-xml php-xmlrpc php-curl php-gd \
    php-imagick php-mbstring php-opcache php-soap php-zip php-ioncube-loader php-devel
elif [ "$phpversion" = "2" ];then
    sudo dnf -vy module enable php:remi-7.3
    sudo dnf -vy install php php-cli php-common php-fpm php-mysqlnd php-xml php-xmlrpc php-curl php-gd \
    php-imagick php-mbstring php-opcache php-soap php-zip php-ioncube-loader php-devel
elif [ "$phpversion" = "3" ];then
    sudo dnf -vy module enable php:remi-7.4
    sudo dnf -vy install php php-cli php-common php-fpm php-mysqlnd php-xml php-xmlrpc php-curl php-gd \
    php-imagick php-mbstring php-opcache php-soap php-zip php-ioncube-loader php-devel
elif [ "$phpversion" = "4" ];then
    sudo dnf -vy module enable php:remi-8.0
    sudo dnf -vy install php php-cli php-common php-fpm php-mysqlnd php-xml php-xmlrpc php-curl php-gd \
    php-imagick php-mbstring php-opcache php-soap php-zip php-ioncube-loader
elif [ "$phpversion" = "5" ];then
    sudo dnf -vy module enable php:remi-8.1
    sudo dnf -vy install php php-cli php-common php-fpm php-mysqlnd php-xml php-xmlrpc php-curl php-gd \
    php-imagick php-mbstring php-opcache php-soap php-zip php-devel
else
    echo "Out of option Please Choose between 1-5"
fi
printf "\nPHP installation Has Finished\n\n"