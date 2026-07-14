#!/bin/bash

# 6-FFmpeg
printf "\nPlease Choose Your Desired FFmpeg Version \n\n1-)FFmpeg (Official Package)\n2-)FFmpeg Latest(Compile From Source)\n\
3-)FFmpeg Latest(Snap)\n\nPlease Select Your FFmpeg Version:"
read -r ffmpeg_version
if [ "$ffmpeg_version" = "1" ];then
    cd /root/Downloads/ffmpeglatest/
    make -j "$core" uninstall
    snap remove ffmpeg
    sudo dnf -vy install ffmpeg ffmpeg-devel ffmpeg-libs
elif [ "$ffmpeg_version" = "2" ];then
    sudo dnf -vy install gcc
    sudo snap remove ffmpeg
    sudo dnf -vy remove ffmpeg ffmpeg-devel ffmpeg-libs
    sudo mkdir -pv /root/Downloads/ffmpeglatest
    ffmpeg_latest=$(lynx -dump https://www.ffmpeg.org/releases/ | awk '/http/{print $2}' | grep -iv '.asc\|md5\|snapshot' | \
    grep -i tar.gz | tail -n 1)
    sudo wget -O /root/Downloads/ffmpeglatest.tar.gz "$ffmpeg_latest"
    tar xvf /root/Downloads/ffmpeglatest.tar.gz -C /root/Downloads/ffmpeglatest --strip-components 1
    cd /root/Downloads/ffmpeglatest/
    ./configure --disable-x86asm
    make -j "$core" && make -j "$core" install
elif [ "$ffmpeg_version" = "3" ];then
    sudo dnf -vy remove ffmpeg ffmpeg-devel ffmpeg-libs
    cd /root/Downloads/ffmpeglatest/
    make -j "$core" uninstall
    sudo snap install ffmpeg
else 
    echo "Out of option Please Choose between 1-3"
fi
