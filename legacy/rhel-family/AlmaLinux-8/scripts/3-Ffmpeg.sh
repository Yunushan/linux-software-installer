#!/bin/bash

#3-FFMPEG
printf "\nPlease Choose Your Desired FFmpeg Version\n\n1-)FFmpeg Stable\n2-)FFmpeg Latest (Edge)\n\n\
Please Select Your FFMPEG Version:"
read -r ffmpegversion
if [ "$ffmpegversion" = "1" ];then
    sudo snap install ffmpeg
    printf "\nFFmpeg Stable Installation Has Finished\n\n"
elif [ "$ffmpegversion" = "2" ];then
    sudo snap install ffmpeg --edge
    printf "\nFFmpeg Latest (Edge) Installation Has Finished\n\n"
else
    echo "Out of option(s) please choose between 1-2"
    :
fi