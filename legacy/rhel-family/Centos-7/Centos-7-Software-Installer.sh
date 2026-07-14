#!/bin/bash

# Variables
cpuarch=$(uname -m)
core=$(nproc)
snap_path_is_include=$(export PATH="$PATH:/snap/bin/")
scripts_path=$(find / -name scripts | grep -i "Centos-7/scripts" | head -n 1)
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
    options=("PHP ${opts[1]}" "Nginx ${opts[2]}" "FFmpeg ${opts[3]}" "GCC4.8 - Latest From Source ${opts[4]}"
    "G++ ${opts[5]}" "Cmake ${opts[6]}" "VLC ${opts[7]}" "Apache2 ${opts[8]}" "Monitoring Tools ${opts[9]}"
    "Transmission-cli ${opts[10]}" "Nmap ${opts[11]}" "Irssi (IRC) ${opts[12]}" "Timeshift ${opts[13]}"
    "Jenkins ${opts[14]}" "Docker ${opts[15]}" "Weechat (IRC) ${opts[16]}" "Quassel (IRC) ${opts[17]}"
    "Neofetch ${opts[18]}" "GNU Emacs ${opts[19]}" "Kubectl ${opts[20]}" "Magic Wormhole ${opts[21]}"
    "Neovim ${opts[22]}" "OpenJDK 8-11-17 ${opts[23]}" "Deluge ${opts[24]}" "Snap ${opts[25]}"
    "WineHQ From Source ${opts[26]}" "VMware Workstation Pro ${opts[27]}" "Telegram ${opts[28]}"
    "Screenfetch ${opts[29]}" "Postman ${opts[30]}" "DBeaver-CE ${opts[31]}" "Anydesk ${opts[32]}"
    "Jitsi ${opts[33]}" "DVBlast ${opts[34]}" "ElectronMail ${opts[35]}" "PyCharm Community Edition ${opts[36]}"
    "Gimp Latest ${opts[37]}" "Linux Kernel ${opts[38]}" "Samba ${opts[39]}" "Mysql ${opts[40]}" "Mariadb ${opts[41]}"
    "Nodejs & Npm ${opts[42]}" ".NET SDK ${opts[43]}" "Tinc ${opts[44]}" "Zabbix Server ${opts[45]}" "Done ${opts[46]}")
    select opt in "${options[@]}";do
        case $opt in
            "PHP ${opts[1]}")
                choice 1
                break
                ;;
            "Nginx ${opts[2]}")
                choice 2
                break
                ;;
            "FFmpeg ${opts[3]}")
                choice 3
                break
                ;;
            "GCC4.8 - Latest From Source ${opts[4]}")
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
            "Monitoring Tools ${opts[9]}")
                choice 9
                break
                ;;
            "Transmission-cli ${opts[10]}")
                choice 10
                break
                ;;
            "Nmap ${opts[11]}")
                choice 11
                break
                ;;
            "Irssi (IRC) ${opts[12]}")
                choice 12
                break
                ;;
            "Timeshift ${opts[13]}")
                choice 13
                break
                ;;
            "Jenkins ${opts[14]}")
                choice 14
                break
                ;;
            "Docker ${opts[15]}")
                choice 15
                break
                ;;
            "Weechat (IRC) ${opts[16]}")
                choice 16
                break
                ;;
            "Quassel (IRC) ${opts[17]}")
                choice 17
                break
                ;;
            "Neofetch ${opts[18]}")
                choice 18
                break
                ;;
            "GNU Emacs ${opts[19]}")
                choice 19
                break
                ;;
            "Kubectl ${opts[20]}")
                choice 20
                break
                ;;
            "Magic Wormhole ${opts[21]}")
                choice 21
                break
                ;;
            "Neovim ${opts[22]}")
                choice 22
                break
                ;;
            "OpenJDK 8-11-17 ${opts[23]}")
                choice 23
                break
                ;;
            "Deluge ${opts[24]}")
                choice 24
                break
                ;;
            "Snap ${opts[25]}")
                choice 25
                break
                ;;
            "WineHQ From Source ${opts[26]}")
                choice 26
                break
                ;;
            "VMware Workstation Pro ${opts[27]}")
                choice 27
                break
                ;;
            "Telegram ${opts[28]}")
                choice 28
                break
                ;;
            "Screenfetch ${opts[29]}")
                choice 29
                break
                ;;
            "Postman ${opts[30]}")
                choice 30
                break
                ;;
            "DBeaver-CE ${opts[31]}")
                choice 31
                break
                ;;
            "Anydesk ${opts[32]}")
                choice 32
                break
                ;;
            "Jitsi ${opts[33]}")
                choice 33
                break
                ;;
            "DVBlast ${opts[34]}")
                choice 34
                break
                ;;
            "ElectronMail ${opts[35]}")
                choice 35
                break
                ;;
            "PyCharm Community Edition ${opts[36]}")
                choice 36
                break
                ;;
            "Gimp Latest ${opts[37]}")
                choice 37
                break
                ;;
            "Linux Kernel ${opts[38]}")
                choice 38
                break
                ;;
            "Samba ${opts[39]}")
                choice 39
                break
                ;;
            "Mysql ${opts[40]}")
                choice 40
                break
                ;;
            "Mariadb ${opts[41]}")
                choice 41
                break
                ;;
            "Nodejs & Npm ${opts[42]}")
                choice 42
                break
                ;;
            ".NET SDK ${opts[43]}")
                choice 43
                break
                ;;
            "Tinc ${opts[44]}")
                choice 44
                break
                ;;
            "Zabbix Server ${opts[45]}")
                choice 45
                break
                ;;
            "Done ${opts[46]}")
                break 2
                ;;
            *) printf '%s\n' 'Please Choose Between 1-46';;
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
sudo yum -y update
sudo yum -y install epel-release
sudo yum -y install wget curl mlocate nano lynx net-tools htop git redhat-lsb-core dnf
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo echo 'export PATH="$PATH:/snap/bin/"' >> /etc/profile
source /etc/profile
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
            9)
            #9-Monitoring-Tools
            . "$scripts_path/9-Monitoring-Tools.sh"
            ;;
            10)
            #10-Transmission
            . "$scripts_path/10-Transmission.sh"
            ;;
            11)
            #11-Nmap
            . "$scripts_path/11-Nmap.sh"
            ;;
            12)
            #12-Irssi
            . "$scripts_path/12-Irssi.sh"
            ;;
            13)
            #13-Timeshift
            . "$scripts_path/13-Timeshift.sh"
            ;;
            14)
            #14-Jenkins
            . "$scripts_path/14-Jenkins.sh"
            ;;
            15)
            #15-Docker
            . "$scripts_path/15-Docker.sh"
            ;;
            16)
            #16-Weechat
            . "$scripts_path/16-Weechat.sh"
            ;;
            17)
            #17-Quassel
            . "$scripts_path/17-Quassel.sh"
            ;;
            18)
            #18-Neofetch
            . "$scripts_path/18-Neofetch.sh"
            ;;
            19)
            #19-Gnu-Emacs
            . "$scripts_path/19-Gnu-Emacs.sh"
            ;;
            20)
            #20-Kubectl
            . "$scripts_path/20-Kubectl.sh"
            ;;
            21)
            #21-Magic-Wormhole
            . "$scripts_path/21-Magic-Wormhole.sh"
            ;;
            22)
            #22-Neovim
            . "$scripts_path/22-Neovim.sh"
            ;;
            23)
            #23-Openjdk
            . "$scripts_path/23-Openjdk.sh"
            ;;
            24)
            #24-Deluge
            . "$scripts_path/24-Deluge.sh"
            ;;
            25)
            #25-Snap
            . "$scripts_path/25-Snap.sh"
            ;;
            26)
            #26-Winehq
            . "$scripts_path/26-Winehq.sh"
            ;;
            27)
            #27-Vmware-Workstation-Pro
            . "$scripts_path/27-Vmware-Workstation-Pro.sh"
            ;;
            28)
            #28-Telegram
            . "$scripts_path/28-Telegram.sh"
            ;;
            29)
            #29-Screenfetch
            . "$scripts_path/29-Screenfetch.sh"
            ;;
            30)
            #30-Postman
            . "$scripts_path/30-Postman.sh"
            ;;
            31)
            #31-Dbeaver-Ce
            . "$scripts_path/31-Dbeaver-Ce.sh"
            ;;
            32)
            #32-Anydesk
            . "$scripts_path/32-Anydesk.sh"
            ;;
            33)
            #33-Jitsi
            . "$scripts_path/33-Jitsi.sh"
            ;;
            34)
            #34-Dvblast
            . "$scripts_path/34-Dvblast.sh"
            ;;
            35)
            #35-Electronmail
            . "$scripts_path/35-Electronmail.sh"
            ;;
            36)
            #36-Pycharm-Community
            . "$scripts_path/36-Pycharm-Community.sh"
            ;;
            37)
            #37-Gimp
            . "$scripts_path/37-Gimp.sh"
            ;;
            38)
            #38-Linux-Kernel
            . "$scripts_path/38-Linux-Kernel.sh"
            ;;
            39)
            #39-Samba
            . "$scripts_path/39-Samba.sh"
            ;;
            40)
            #40-Mysql
            . "$scripts_path/40-Mysql.sh"
            ;;
            41)
            #41-Mariadb
            . "$scripts_path/40-Mariadb.sh"
            ;;
            42)
            #42-Nodejs-And-Npm
            . "$scripts_path/42-Nodejs-And-Npm.sh"
            ;;
            43)
            #43-.Net-Sdk
            . "$scripts_path/43-.Net-Sdk.sh"
            ;;
            44)
            #44-Tinc
            . "$scripts_path/44-Tinc.sh"
            ;;
            45)
            #45-Zabbix-Server
            . "$scripts_path/45-Server.sh"
            ;;
        esac
    fi
done
