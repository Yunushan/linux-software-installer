#!/bin/bash

#3-FFMPEG 
sudo yum install epel-release -y
sudo rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el6/x86_64/nux-dextop-release-0-2.el6.nux.noarch.rpm
sudo yum install ffmpeg ffmpeg-devel -y
printf "\nFFmpeg installation Has Finished\n\n"