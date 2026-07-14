#!/bin/bash

#42-Composer
printf "\nPlease Choose Your Desired Composer\n1-)Composer(Composer programmatically)\n\
2-)Composer (Command-Line Installation)\n3-)Composer (Stable Version)\n\
4-)Composer (LTS Version)\n\nPlease Select Your Composer Version:"
read -r composer_version
if [ "$composer_version" = "1" ];then
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ];then
        >&2 echo 'ERROR: Invalid installer checksum'
        rm composer-setup.php
        exit 1
    fi
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    RESULT=$?
    rm composer-setup.php
    exit $RESULT
    #sudo mv composer.phar /usr/local/bin/composer
elif [ "$composer_version" = "2" ];then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === \
    '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') \
    { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    php -r "unlink('composer-setup.php');"
    #sudo mv composer.phar /usr/local/bin/composer
elif [ "$composer_version" = "3" ];then
    latest_stable_composer=$(lynx -dump https://getcomposer.org/download/ | awk '/http/{print $2}' | grep -iv 'sha256\|asc' \
    | grep -i stable | head -n 1)
    sudo wget -O /root/Downloads/stable-composer.phar "$latest_stable_composer"
    sudo mv -v /root/Downloads/stable-composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
elif [ "$composer_version" = "4" ];then
    latest_lts_composer=$(lynx -dump https://getcomposer.org/download/ | awk '/http/{print $2}' \
    | grep -iv '.sha\|asc' | grep -i latest-2.2.x | head -n 1)
    sudo wget -O /root/Downloads/lts-composer.phar "$latest_lts_composer"
    sudo mv -v /root/Downloads/lts-composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
else
    echo "Out of options please choose between 1-4"
fi