#!/bin/bash

#22-Neovim
printf "\nPlease Choose Your Desired Neovim Version\n\n1-)Neovim Kalikiana (Snap) \n\
2-)Install Neovim From Source (Newer version)\n\nPlease Select Your Neovim Version:"
read -r neovimversion
if [ "$neovimversion" = "1" ];then
    sudo snap install neovim-kalikiana
    printf "\nNeovim Kalikiana (Snap)\n\n"
elif [ "$neovimversion" = "2" ];then
    sudo dnf -vy install gcc-c++ automake libtool gcc cmake make
    neovimstable=$(lynx -dump https://github.com/neovim/neovim/releases/ | awk '{print $2}' | grep 'stable\|.tar.gz' \
    | grep -v 'macos\|linux' | head -n 1)
    sudo wget -O /root/Downloads/neovim-stable.tar.gz "$neovimstable"
    sudo mkdir -pv /root/Downloads/neovim-stable/
    tar xvf /root/Downloads/neovim-stable.tar.gz -C /root/Downloads/neovim-stable/ --strip-components 1
    cd /root/Downloads/neovim-stable/
    mkdir -p "$HOME"/opt
    make CMAKE_INSTALL_PREFIX="$HOME"/opt install
    make install
    printf "\n Neovim From Source (Newer version) Installation Has Finished\n\n"
fi