#!/bin/bash

#33-Links (Text based web browser)
sudo dnf -vy install libpng libpng-devel libtiff libtiff-devel gpm gpm-devel tar gzip bzip2 zlib zlib-devel gcc make
printf "\nPlease Choose Your Desired Links Version\n\n1-)Links (Snap) \n\
2-)Links (Compile From Source)\n\nPlease Select Your Links Version:"
read -r links_version
if [ "$links_version" = "1" ];then
    cd /root/Downloads/links-latest
    make -j "$core" uninstall
    sudo snap install links
elif [ "$links_version" = "2" ];then
    sudo snap remove links
    links_latest=$(lynx -dump http://links.twibright.com/download.php | awk '/http/{print $2}' | grep -i tar.gz | head -n 1)
    sudo wget -O /root/Downloads/links-latest.tar.gz "$links_latest"
    sudo mkdir -pv /root/Downloads/links-latest
    tar xzvf /root/Downloads/links-latest.tar.gz -C /root/Downloads/links-latest --strip-components 1
    cd /root/Downloads/links-latest
    ./configure --enable-graphics
    make -j "$core" && make -j "$core" install
else
    echo "Out of options please choose between 1-2"
fi