#!/bin/bash

#3-Python
printf "\nPlease Choose Your Desired Python Version\n\n1-)Python 2 (Official Package)\n2-)Python 3.6 (Official Package)\n\
3-)Python 3.8 (Official Package)\n4-)Python 3.9 (Official Package)\n5-)Python 3.10.3 (Compile From Source)\n\n\
Please Select Your Python Version:"
read -r python_version
if [ "$python_version" = "1" ];then
    sudo dnf -vy install python2 python2-devel
elif [ "$python_version" = "2" ];then
    sudo dnf -vy install python36 python36-devel
elif [ "$python_version" = "3" ];then
    sudo dnf -vy install python38 python38-devel
elif [ "$python_version" = "4" ];then
    sudo dnf -vy install python39 python39-devel
elif [ "$python_version" = "5" ];then
    sudo dnf -vy install gcc wget make bzip2-devel openssl-devel zlib-devel libffi-devel \
    ncurses-devel gdbm-devel xz-devel sqlite-devel readline-devel libuuid-devel uuid-devel \
    tk-devel bzip2-devel
    sudo dnf -vy groupinstall "Development Tools"
    sudo mkdir -pv /root/Downloads/Python-3.10.3
    wget -O /root/Downloads/Python-3.10.3.tgz https://www.python.org/ftp/python/3.10.3/Python-3.10.3.tgz
    tar -xvf /root/Downloads/Python-3.10.3.tgz -C /root/Downloads/Python-3.10.3 --strip-components 1
    cd /root/Downloads/Python-3.10.3
    ./configure --enable-loadable-sqlite-extensions \
                --enable-optimizations \
                --with-system-ffi \
                --enable-shared \
                --with-ensurepip=yes \
                --with-system-expat \
                --with-computed-gotos
    make -j "$core" && make -j "$core" altinstall
else
    echo "Out of option Please Choose between 1-4"
fi