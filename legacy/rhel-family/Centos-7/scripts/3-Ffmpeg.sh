#!/bin/bash

#3-FFMPEG
printf "\nPlease Choose Your Desired FFmpeg Version\n\n1-)FFmpeg 2.8\n2-)FFmpeg Stable (Snap)\n3-)FFmpeg Latest (Snap)\n\nPlease Select Your FFmpeg Version:"
read -r ffmpegversion
if [ "$ffmpegversion" = "1" ];then
    sudo snap remove ffmpeg
    sudo yum install epel-release -y
    sudo rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
    sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
    sudo yum install ffmpeg ffmpeg-devel -y
elif [ "$ffmpegversion" = "2" ];then
    sudo yum remove -y ffmpeg*
    sudo snap remove ffmpeg
    sudo snap install ffmpeg
    sleep 2
    sudo ln -s /var/lib/snapd/snap /snap
    sudo echo 'export PATH="$PATH:/snap/bin/"' >> /etc/profile
    source /etc/profile
elif [ "$ffmpegversion" = "3" ];then
    sudo yum remove -y ffmpeg*
    sudo snap remove ffmpeg
    sudo snap install ffmpeg --edge
    sudo ln -s /var/lib/snapd/snap /snap
    sudo echo 'export PATH="$PATH:/snap/bin/"' >> /etc/profile
    source /etc/profile
else
    echo "Out of options please choose between 1-3"
fi
printf "\nFFmpeg installation Has Finished\n\n"