#!/bin/bash

#25-Vim
printf "\nPlease Choose Your Desired Vim Version\n1-)Vim Version (Official Package Manager)\n\
2-)Vim Latest (Compile From Source)\n\nPlease Select Your Vim Version:"
read -r vim_version
if [ "$vim_version" = "1" ];then
    sudo dnf -vy install vim-enhanced
elif [ "$vim_version" = "2" ];then
    sudo dnf -vy install git make ncurses-devel
    git clone https://github.com/vim/vim.git /root/Downloads/vim
    cd /root/Downloads/vim/src
    ./configure --with-features=huge \
        --enable-multibyte \
        --enable-rubyinterp \
        --enable-pythoninterp \
        --enable-perlinterp \
        --enable-luainterp
    make -j "$core" && make -j "$core" install
else
    echo "Out of options please choose between 1-2"
fi