#!/bin/bash

#1-Php
printf "\nPlease Choose Your Desired PHP Version \n\n1-) PHP 8.0 (Red Hat Official Package)\n\
2-) PHP 7.4 (Remi Release)\n3-) PHP 8.1 (Remi Release)\n4-) PHP 8.2 (Remi Release)\n\nPlease Select Your PHP Version:"
read -r php_version
if [ "$php_version" = "1" ]
then
    sudo dnf -vy install php php-cli php-common php-fpm php-mysqlnd php-xml php-curl php-gd \
    php-imagick php-mbstring php-opcache php-soap php-zip php-devel
elif [ "$php_version" = "2" ]
then
    sudo dnf -vy install dnf-utils https://rpms.remirepo.net/enterprise/remi-release-9.rpm
    sudo dnf -vy install php74-php php74-php-cli php74-php-common php74-php-fpm php74-php-mysqlnd php74-php-xml \
    php74-php-curl php74-php-gd php74-php-imagick php74-php-mbstring php74-php-opcache php74-php-soap php74-php-zip \
    php74-php-devel
elif [ "$php_version" = "3" ]
then
    sudo dnf -vy install dnf-utils https://rpms.remirepo.net/enterprise/remi-release-9.rpm
    sudo dnf -vy install php81-php php81-php-cli php81-php-common php81-php-fpm php81-php-mysqlnd php81-php-xml \
    php81-php-curl php81-php-gd php81-php-imagick php81-php-mbstring php81-php-opcache php81-php-soap \
    php81-php-zip php81-php-devel
elif [ "$php_version" = "4" ]
then
    sudo dnf -v install php82-php php82-php-cli php82-php-common php82-php-fpm php82-php-mysqlnd php82-php-xml \
    php82-php-curl php82-php-gd php82-php-mbstring php82-php-opcache php82-php-soap php82-php-zip php82-php-develx
else
    echo "Out of option Please Choose between 1-4"
fi
printf "\nPHP installation Has Finished\n\n"