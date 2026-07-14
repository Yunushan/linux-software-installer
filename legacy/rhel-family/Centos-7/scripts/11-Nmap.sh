#!/bin/bash

#11-Nmap
printf "\nPlease Choose Your Desired Nmap Version\n\n1-)Nmap (From Official Package)\n2-)Nmap Latest\n\nPlease Select Your Nmap Version:"
read -r nmapversion
if [ "$nmapversion" = "1" ];then
    sudo yum -y install nmap
elif [ "$nmapversion" = "2" ];then
    nmap64=$(lynx -dump https://nmap.org/dist/ | awk '/nmap-7.*\.x86_64.rpm$/{url=$2}END{print url}')
    sudo rpm -Uvh "$nmap64"
else
    echo "Out of options please choose between 1-2"
fi