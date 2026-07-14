#!/bin/bash

#7-FFmpeg
sudo mkdir -pv /root/Downloads/ffmpeglatest
ffmpeg_latest=$(lynx -dump https://www.ffmpeg.org/releases/ | awk '/http/{print $2}' | grep -iv '.asc\|md5\|snapshot' \
| grep -i tar.gz | tail -n 1)
sudo wget -O /root/Downloads/ffmpeglatest.tar.gz "$ffmpeg_latest"
tar xvf /root/Downloads/ffmpeglatest.tar.gz -C /root/Downloads/ffmpeglatest --strip-components 1
cd /root/Downloads/ffmpeglatest/
./configure --disable-x86asm
make -j "$core" && make -j "$core" install