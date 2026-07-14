#!/bin/bash

# Variables
cpuarch=$(uname -m)
core=$(nproc)
snap_path_is_include=$(export PATH="$PATH:/snap/bin/")
scripts_path=$(find / -name scripts | grep -i "Red-Hat-Enterprise-Linux-9/scripts" | head -n 1)

# Select Which Softwares to be Installed

choice () {
    local choice=$1
    if [[ ${opts[choice]} ]] # toggle
    then
        opts[choice]=
    else
        opts[choice]=+
    fi
}
PS3='
Please enter your choice(s): '
while :
do
    clear
    options=("PHP ${opts[1]}" "Nginx ${opts[2]}" "Apache ${opts[3]}" "Grub Customizer ${opts[4]}" "Linux Kernel ${opts[5]}"
    "FFmpeg ${opts[6]}" "OpenSSL ${opts[7]}" "OpenSSH ${opts[8]}" "Mysql ${opts[9]}" "OpenJDK 8-11-17 ${opts[10]}"
    "DVBlast 3.4 ${opts[11]}" "Zabbix Server ${opts[12]}" "UrBackup Server ${opts[13]}" "PostgreSQL ${opts[14]}"
    "Nodejs-And-Npm ${opts[15]}" "Winehq ${opts[16]}" "Pgadmin ${opts[17]}" "Pgagent ${opts[18]}" "Wazuh Server ${opts[19]}"
    "Phpmyadmin ${opts[20]}" "Elasticsearch ${opts[21]}" "Logstash ${opts[22]}" "Kibana ${opts[23]}"
    "Google-Authenticator ${opts[24]}" "Vim ${opts[25]}" "Gocd ${opts[26]}" "Jenkins ${opts[27]}" "Passbolt-Ce ${opts[28]}"
    "Fail2ban ${opts[29]}" "Tinc ${opts[30]}" "Done ${opts[31]}")
    select opt in "${options[@]}"
    do
        case $opt in
            "PHP ${opts[1]}")
                choice 1
                break
                ;;
            "Nginx ${opts[2]}")
                choice 2
                break
                ;;
            "Apache ${opts[3]}")
                choice 3
                break
                ;;
            "Grub Customizer ${opts[4]}")
                choice 4
                break
                ;;
            "Linux Kernel ${opts[5]}")
                choice 5
                break
                ;;
            "FFmpeg ${opts[6]}")
                choice 6
                break
                ;;
            "OpenSSL ${opts[7]}")
                choice 7
                break
                ;;
            "OpenSSH ${opts[8]}")
                choice 8
                break
                ;;
            "Mysql ${opts[9]}")
                choice 9
                break
                ;;
            "OpenJDK 8-11-17 ${opts[10]}")
                choice 10
                break
                ;;
            "DVBlast 3.4 ${opts[11]}")
                choice 11
                break
                ;;
            "Zabbix Server ${opts[12]}")
                choice 12
                break
                ;;
            "UrBackup Server ${opts[13]}")
                choice 13
                break
                ;;
            "PostgreSQL ${opts[14]}")
                choice 14
                break
                ;;
            "Nodejs-And-Npm ${opts[15]}")
                choice 15
                break
                ;;
            "Winehq ${opts[16]}")
                choice 16
                break
                ;;
            "Pgadmin ${opts[17]}")
                choice 17
                break
                ;;
            "Pgagent ${opts[18]}")
                choice 18
                break
                ;;
            "Wazuh Server ${opts[19]}")
                choice 19
                break
                ;;
            "Phpmyadmin ${opts[20]}")
                choice 20
                break
                ;;
            "Elasticsearch ${opts[21]}")
                choice 21
                break
                ;;
            "Logstash ${opts[22]}")
                choice 22
                break
                ;;
            "Kibana ${opts[23]}")
                choice 23
                break
                ;;
            "Google-Authenticator ${opts[24]}")
                choice 24
                break
                ;;
            "Vim ${opts[25]}")
                choice 25
                break
                ;;
            "Gocd ${opts[26]}")
                choice 26
                break
                ;;
            "Jenkins ${opts[27]}")
                choice 27
                break
                ;;
            "Passbolt-Ce ${opts[28]}")
                choice 28
                break
                ;;
            "Fail2ban ${opts[29]}")
                choice 29
                break
                ;;
            "Tinc ${opts[30]}")
                choice 30
                break
                ;;
            "Done ${opts[31]}")
                break 2
                ;;

            *) printf '%s\n' 'Please Choose Between 1-31';;
        esac
    done
done

printf '%s\n\n' 'Options chosen:'
for opt in "${!opts[@]}"
do
    if [[ ${opts[opt]} ]]
    then
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
CODEREADY_BUILDER=$(yum repolist | grep -qi "codeready-builder-for-rhel")
if [ -z "$CODEREADY_BUILDER" ];then
    :
else
    sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpm
fi

sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -vy install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm
sudo dnf -vy install wget curl mlocate nano lynx net-tools htop git dnf yum snapd bash-completion dnf-utils
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo systemctl start snapd
export PATH=$PATH:/snap/bin
source /etc/profile
source /etc/profile.d/bash_completion.sh
printf "\n"
local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# Create Download Folder in root
if [ -d "/root/Downloads/" ];then
    :
else
    sudo mkdir -pv /root/Downloads/
fi

# INSTALLATION BY SELECTION

for opt in "${!opts[@]}"
do
    if [[ ${opts[opt]} ]]
    then
        case $opt in 
            1) 
            #PHP
            . "$scripts_path/1-Php.sh"
            ;;
            2)
            # 2- Nginx
            . "$scripts_path/2-Nginx.sh"
            ;;
            3)
            # 3- Apache
            . "$scripts_path/3-Apache.sh"
            ;;
            4)
            # 4- Grub Customizer
            . "$scripts_path/4-Grub-Customizer.sh"
            ;;
            5)
            # 5-Linux Kernel
            . "$scripts_path/5-Linux-Kernel.sh"
            ;;
            6)
            # 6-FFmpeg
            . "$scripts_path/6-Ffmpeg.sh"
            ;;
            7)
            # 7-OpenSSL
            . "$scripts_path/7-Openssl.sh"
            ;;
            8)
            # 8-OpenSSH
            . "$scripts_path/8-Openssh.sh"
            ;;
            9)
            # 9-Mysql
            . "$scripts_path/8-Openssh.sh"
            ;;
            10)
            # 10-OpenJDK 8-11-17
            . "$scripts_path/10-Openjdk.sh"
            ;;
            11)
            # 11-DVBlast 3.4
            . "$scripts_path/11-Dvblast.sh"
            ;;
            12)
            # 12-Zabbix Server
            . "$scripts_path/12-Zabbix-Server.sh"
            ;;
            13)
            # 13-UrBackup Server
            . "$scripts_path/13-Urbackup-Server.sh"
            ;;
            14)
            # 14-PostgreSQL
            . "$scripts_path/14-Postgresql.sh"
            ;;
            15)
            # 15-Nodejs-And-Npm
            . "$scripts_path/15-Nodejs-And-Npm.sh"
            ;;
            16)
            # 16-Winehq
            . "$scripts_path/16-Winehq.sh"
            ;;
            17)
            # 17-Pgadmin
            . "$scripts_path/17-Pgadmin.sh"
            ;;
            18)
            # 18-Pgagent
            . "$scripts_path/18-Pgagent.sh"
            ;;
            19)
            # 19-Wazuh-Server
            . "$scripts_path/19-Wazuh-Server.sh"
            ;;
            20)
            # 20-Phpmyadmin
            . "$scripts_path/20-Phpmyadmin.sh"
            ;;
            21)
            # 21-Elasticsearch
            . "$scripts_path/21-Elasticsearch.sh"
            ;;
            22)
            # 22-Logstash
            . "$scripts_path/22-Logstash.sh"
            ;;
            23)
            # 23-Kibana
            . "$scripts_path/23-Kibana.sh"
            ;;
            24)
            # 24-Google-Authenticator
            . "$scripts_path/24-Google-Authenticator.sh"
            ;;
            25)
            # 25-Vim
            . "$scripts_path/25-Vim.sh"
            ;;
            26)
            # 26-Gocd
            . "$scripts_path/26-Gocd.sh"
            ;;
            27)
            # 27-Jenkins
            . "$scripts_path/27-Jenkins.sh"
            ;;
            28)
            # 28-Passbolt-Ce
            . "$scripts_path/28-Passbolt-Ce.sh"
            ;;
            29)
            # 29-Fail2ban
            . "$scripts_path/29-Fail2ban.sh"
            ;;
            30)
            # 30-Tinc
            . "$scripts_path/30-Tinc.sh"
            ;;
        esac
    fi
done