#!/bin/bash

#1-PHP 7.4 - 8.1
sudo dnf -vy install http://rpms.remirepo.net/enterprise/remi-release-9.rpm
printf "\nPlease Choose Your Desired PHP Version\n\n1-)PHP7.4\n2-)PHP8.0\n3-)PHP8.1\n\nPlease Select Your PHP Version:"
read phpversion
if [ "$phpversion" = "1" ];then
    sudo dnf -vy install php74 php74-php-pecl-mysql php74-php-ioncube-loader php74-php-pecl-memcache php74-php-pecl-memcached
elif [ "$phpversion" = "2" ];then
    sudo dnf -vy install php80 php80-php-pecl-mysql php80-php-pecl-memcache php80-php-pecl-memcached
elif [ "$phpversion" = "3" ];then
    sudo dnf -vy install php81 php81-php-pecl-mysql php81-php-pecl-memcache php81-php-pecl-memcached
elif [ "$phpversion" = "4" ];then
    sudo dnf -vy install php82 php82-php-pecl-mysql php82-php-pecl-memcache php82-php-pecl-memcached
else
    echo "Out of option Please Choose between 1-3"
:
fi
printf "\nPHP installation Has Finished\n\n"