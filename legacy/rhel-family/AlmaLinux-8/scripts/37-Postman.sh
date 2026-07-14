#!/bin/bash

#37-Postman
printf "\nPlease Choose Your Desired Postman Version \n\n1-)Postman (Snap)\n2-)Postman (From .tar.gz File)\n\n\
Please Select Your Postman Version:"
read -r postman_version
if [ "$postman_version" = "1" ];then
    sudo snap install postman
elif [ "$postman_version" = "2" ];then
    sudo mkdir -pv /root/Downloads/postman-latest
    wget -O /root/Downloads/postman-latest.tar.gz https://dl.pstmn.io/download/latest/linux64
    tar xvf /root/Downloads/postman-latest.tar.gz -C /root/Downloads/postman-latest --strip-components 1
    sudo ln -s /root/Downloads/Postman /usr/local/bin/postman
else
    echo "Out of options please choose between 1-2"
fi