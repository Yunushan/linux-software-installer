#!/bin/bash

# Variables
cpuarch=$(uname -m)
scripts_path=$(find / -name scripts | grep -i "Centos-6/scripts" | head -n 1)
if [[ $(rpm -qa | grep -i net-tools) ]];then
    local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
else
    dnf -vy install net-tools
    local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
fi
# Select Which Softwares to be Installed

choice () {
    local choice=$1
    if [[ ${opts[choice]} ]];then # toggle
        opts[choice]=
    else
        opts[choice]=+
    fi
}
PS3='
Please enter your choice(s): '
while :;do
    clear
    options=("PHP7.1 ${opts[1]}" "Nginx ${opts[2]}" "FFMPEG ${opts[3]}" "GCC ${opts[4]}" "G++ ${opts[5]}" 
    "Cmake ${opts[6]}" "VLC ${opts[7]}" "Apache2 ${opts[8]}" "Done ${opts[9]}")
    select opt in "${options[@]}";do
        case $opt in
            "PHP7.1 ${opts[1]}")
                choice 1
                break
                ;;
            "Nginx ${opts[2]}")
                choice 2
                break
                ;;
            "FFMPEG ${opts[3]}")
                choice 3
                break
                ;;
            "GCC ${opts[4]}")
                choice 4
                break
                ;;
            "G++ ${opts[5]}")
                choice 5
                break
                ;;
            "Cmake ${opts[6]}")
                choice 6
                break
                ;;
            "VLC ${opts[7]}")
                choice 7
                break
                ;;
            "Apache2 ${opts[8]}")
                choice 8
                break
                ;;
            "Done ${opts[9]}")
                break 2
                ;;
            *) printf '%s\n' 'Please Choose Between 1-9';;
        esac
    done
done

printf '%s\n\n' 'Options chosen:'
for opt in "${!opts[@]}";do
    if [[ ${opts[opt]} ]];then
        printf '%s\n' "Option $opt"
    fi
done

if [ "${opts[opt]}" = "" ];then
    exit
fi

# Loading Bar

printf "Installation starting"
value=0
while [ $value -lt 600 ];do
    value=$((value+20))
    printf "."
    sleep 0.05
done
printf "\n"

sudo yum -vy install wget curl mlocate nano
printf "\n"

# Epel and Remi Repositories Folder
if [ -d "/root/Downloads/epel-and-remi-repositories/" ];then
    :
else
    sudo mkdir -p /root/Downloads/epel-and-remi-repositories/
fi
# Downloaded tmp files
if [ -d "/root/Downloads/TempDL/" ];then
    :
else
    sudo mkdir -p /root/Downloads/TempDL/
fi

# INSTALLATION BY SELECTION

for opt in "${!opts[@]}";do
    if [[ ${opts[opt]} ]];then
        case $opt in 
            1)
            #1-PHP
            . "$scripts_path/1-Php.sh"
            ;;
            2)
            #2-Nginx
            . "$scripts_path/2-Nginx.sh"
            ;;
            3)
            #3-Ffmpeg
            . "$scripts_path/3-Ffmpeg.sh"
            ;;
            4)
            #4-Gcc
            . "$scripts_path/4-Gcc.sh"
            ;;
            5)
            #5-G++
            . "$scripts_path/5-G++.sh"
            ;;
            6)
            #6-Cmake
            . "$scripts_path/6-Cmake.sh"
            ;;
            7)
            #7-Vlc
            . "$scripts_path/7-Vlc.sh"
            ;;
            8)
            #8-Apache
            . "$scripts_path/8-Apache.sh"
            ;;
        esac
    fi
done