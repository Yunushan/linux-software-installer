#!/bin/bash

#36-ClamAV
printf "\nPlease Choose Your Desired ClamAV Version\n\n1-)ClamAV Official Repo (Stable) \n\
2-)ClamAV (Compile From Source)\n\nPlease Select Your ClamAV Version:"
read -r clamav_version
if [ "$clamav_version" = "1" ];then
    sudo dnf -vy install clamav clamav-filesystem clamav-data clamav-devel clamav-lib clamav-milter clamav-update
elif [ "$clamav_version" = "2" ];then
    sudo dnf -vy remove clamav clamav-filesystem clamav-data clamav-devel clamav-lib clamav-milter clamav-update
    sudo dnf -vy install links
    sudo dnf -vy install epel-release
    sudo dnf -vy install dnf-plugins-core
    sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo dnf -vy config-manager --set-enabled PowerTools | \
    sudo dnf -vy config-manager --set-enabled powertools | true
    sudo dnf -vy install \
        `# install tools` \
        gcc gcc-c++ make python3 python3-pip valgrind \
        `# install clamav dependencies` \
        bzip2-devel check-devel json-c-devel libcurl-devel libxml2-devel \
        ncurses-devel openssl-devel pcre2-devel sendmail-devel zlib-devel json-glib json-devel
    python3 -m pip install cmake pytest
    #clamav_latest=$(lynx -dump https://www.clamav.net/downloads)
    wget -O /root/Downloads/clamav-0.104.2.tar.gz https://www.clamav.net/downloads/production/clamav-0.104.2.tar.gz
    sudo mkdir -pv /root/Downloads/clamav-0.104.2
    tar xvf /root/Downloads/clamav-0.104.2.tar.gz -C /root/Downloads/clamav-0.104.2 --strip-components 1
    cd /root/Downloads/clamav-0.104.2
    mkdir build && cd build
    cmake ..
    cmake --build .
    ctest
    sudo cmake --build . --target install
else
    echo "Out of options please choose between 1-2"
fi