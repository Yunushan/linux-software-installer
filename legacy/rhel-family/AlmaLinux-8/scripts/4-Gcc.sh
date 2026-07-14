#!/bin/bash

#4-GCC8.5 - Latest Compile From Source
printf "\nPlease Choose Your Desired GCC Version\n\n1-)GCC 8.5\n2-)GCC Latest (Compile From Source)\n\n\
Please Select Your GCC Version:"
read -r gccversion
if [ "$gccversion" = "1" ];then
    sudo dnf -vy install gcc 
    printf "\nGCC 8.5 Installation Has Finished\n\n"
elif [ "$gccversion" = "2" ];then
    sudo dnf -vy install gcc gcc-c++
    gcc_latest=$(lynx -dump https://ftp.gnu.org/gnu/gcc/ | awk '{print $2}' | grep -iv '.tar.gz\|readme\|hpux\|.diff.gz' \
    | tail -n 1)
    gcc_latest=$(lynx -dump "$gcc_latest" | awk '{print $2}' | grep -i .tar.gz | grep -iv .sig | grep -i .tar.gz | head -n 1)
    sudo wget -O /root/Downloads/gcc-latest.tar.gz "$gcc_latest"
    sudo mkdir -pv /root/Downloads/gcc-latest
    tar xvf /root/Downloads/gcc-latest.tar.gz -C /root/Downloads/gcc-latest --strip-components 1
    cd /root/Downloads/gcc-latest
    contrib/download_prerequisites
    sudo mkdir -pv /root/Downloads/gcc-latest/gcc-latest-build
    cd /root/Downloads/gcc-latest/gcc-latest-build
    ../configure --enable-languages=c,c++ --disable-multilib
    make -j "$core"
    make install
    export PATH=/usr/local/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
    printf "\nGCC Latest Installation Has Finished\n\n"
fi