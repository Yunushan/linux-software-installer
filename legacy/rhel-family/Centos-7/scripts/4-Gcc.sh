#!/bin/bash

#4-GCC4.8 - Latest From Source
sudo yum groupinstall "Development Tools" -y
printf "\nPlease Choose Your Desired GCC Version\n\n1-)GCC Latest From Source\n2-)GCC 4.8\n\nPlease Select Your GCC Version:"
read -r gccversion
if [ "$gccversion" = "1" ];then
    gcc_latest=$(lynx -dump https://ftp.gnu.org/gnu/gcc/ | awk '/http/{print $2}' | grep -i gcc- | grep -iv .gz | tail -n 1)
    gcc_latest=$(lynx -dump "$gcc_latest" | awk '/http/{print $2}' | grep -i .tar.gz | grep -iv .sig | head -n 1)
    sudo wget -O /root/Downloads/gcc-latest.tar.gz "$gcc_latest"
    sudo mkdir -pv /root/Downloads/gcc-latest
    sudo tar xzvf /root/Downloads/gcc-latest.tar.gz -C /root/Downloads/gcc-latest --strip-components 1
    cd /root/Downloads/gcc-latest
    ./contrib/download_prerequisites
    sudo mkdir -pv gcc-latest-build
    cd gcc-latest-build
    ../configure --enable-languages=c,c++ --disable-multilib
    make -j "$core"
    make install
    printf "\nGCC Latest Installation Has Finished\n\n"
elif [ "$gccversion" = "2" ];then
    sudo yum install gcc -y
    printf "\nGCC 4.8 Installation Has Finished\n\n"
fi