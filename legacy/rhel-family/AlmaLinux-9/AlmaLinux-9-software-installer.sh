#!/bin/bash

# Variables
cpuarch=$(uname -m)
core=$(nproc)
scripts_path=$(find / -name scripts | grep -i "AlmaLinux-9/scripts" | head -n 1)
if [[ $(rpm -qa | grep -i net-tools) ]];then
    local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
else
    sudo dnf -vy install net-tools
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
    options=("PHP ${opts[1]}" "Grub Customizer ${opts[2]}" "Snap ${opts[3]}" "Python 2.7.18 ${opts[4]}" 
    "WineHQ Latest ${opts[5]}" "Htop ${opts[6]}" "FFmpeg ${opts[7]}" "Nginx ${opts[8]}" "Linux-Kernel ${opts[9]}" 
    "Openssl ${opts[10]}" "Openssh ${opts[11]}" "Done ${opts[12]}")
    select opt in "${options[@]}";do
        case $opt in
            "PHP ${opts[1]}")
                choice 1
                break
                ;;
            "Grub Customizer ${opts[2]}")
                choice 2
                break
                ;;
            "Snap ${opts[3]}")
                choice 3
                break
                ;;
            "Python 2.7.18 ${opts[4]}")
                choice 4
                break
                ;;
            "WineHQ Latest ${opts[5]}")
                choice 5
                break
                ;;
            "Htop ${opts[6]}")
                choice 6
                break
                ;;
            "FFmpeg ${opts[7]}")
                choice 7
                break
                ;;
            "Nginx ${opts[8]}")
                choice 8
                break
                ;;
            "Linux-Kernel ${opts[9]}")
                choice 9
                break
                ;;
            "Openssl ${opts[10]}")
                choice 10
                break
                ;;
            "Openssh ${opts[11]}")
                choice 11
                break
                ;;
            "Done ${opts[12]}")
                break 2
                ;;
            *) printf '%s\n' 'Please Choose Between 1-12';;
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


#Necessary Packages
sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -vy config-manager --set-enabled crb
sudo dnf -vy dnf config-manager --set-enabled ha
sudo dnf -vy install yum-utils
sudo dnf -vy install wget curl mlocate nano lynx net-tools git tar bash-completion
source /etc/profile.d/bash_completion.sh
printf "\n"

# Create Download Folder in root
if [ -d "/root/Downloads/" ];then
    :
else
    sudo mkdir -pv /root/Downloads/
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
            #2-Grub-Customizer
            . "$scripts_path/2-Grub-Customizer.sh"
            ;;
            3)
            #3-Snap
            . "$scripts_path/3-Snap.sh"
            ;;
            4)
            #4-Python
            . "$scripts_path/4-Python.sh"
            ;;
            5)
            #5-Winehq
            . "$scripts_path/5-Winehq.sh"
            ;;
            6)
            #6-Htop
            . "$scripts_path/6-Htop.sh"
            ;;
            7)
            #7-Ffmpeg
            . "$scripts_path/7-Ffmpeg.sh"
            ;;
            8)
            #8-Nginx
            . "$scripts_path/8-Nginx.sh"
            ;;
            9)
            #9-Linux-Kernel
            . "$scripts_path/9-Linux-Kernel.sh"
            ;;
            10)
            #10-Openssl
            . "$scripts_path/10-Openssl.sh"
            ;;
            11)
            #11-Openssh
            . "$scripts_path/11-Openssh.sh"
            ;;
        esac
    fi
done