#!/bin/bash

# Variables
cpuarch=$(uname -m)
core=$(nproc)
snap_path_is_include=$(export PATH="$PATH:/snap/bin/")
scripts_path=$(find / -name scripts | grep -i "Red-Hat-Enterprise-Linux-8/scripts" | head -n 1)
if [[ $(rpm -qa | grep -i net-tools) ]];then
    local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' \
    | head -n 1)
else
    dnf -vy install net-tools
    local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' \
    | head -n 1)
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
    options=("PHP ${opts[1]}" "Grub Customizer ${opts[2]}" "Python ${opts[3]}" "WineHQ Latest ${opts[4]}" "FFmpeg ${opts[5]}"
    "Apache ${opts[6]}" "Transmission ${opts[7]}" "Nmap ${opts[8]}" "Nginx ${opts[9]}" "Redis ${opts[10]}"
    "OpenSSL ${opts[11]}" "OpenSSH ${opts[12]}" "GoCD ${opts[13]}" "OpenJDK 8-11-17 ${opts[14]}" "DVBlast 3.4 ${opts[15]}"
    "Linux Kernel ${opts[16]}" "Samba ${opts[17]}" "Mysql ${opts[18]}" "Mysql Router ${opts[19]}"
    "Ruby ${opts[20]}" "Flutter ${opts[21]}" "Zabbix Server ${opts[22]}" "UrBackup Server ${opts[23]}"
    "MariaDB ${opts[24]}" "PostgreSQL ${opts[25]}" "Postman ${opts[26]}" "Docker ${opts[27]}"
    "Jenkins ${opts[28]}" "Nodejs & Npm ${opts[29]}" "Tinc ${opts[30]}" "Irssi ${opts[31]}" "OpenNebula ${opts[32]}"
    "Links ${opts[33]}" "MongoDB ${opts[34]}" "Ansible ${opts[35]}" "ClamAV ${opts[36]}" "Graylog ${opts[37]}"
    "VLC ${opts[38]}" "UFW ${opts[39]}" "Fail2ban ${opts[40]}" "Google Authenticator ${opts[41]}" "Composer ${opts[42]}"
    "Podman ${opts[43]}" "NFS Server ${opts[44]}" "Elasticsearch ${opts[45]}" "Kibana ${opts[46]}"
    "pgAdmin ${opts[47]}" "pgAgent ${opts[48]}" "Zabbix Agent ${opts[49]}" "Enterprise Search ${opts[50]}"
    "Logstash ${opts[51]}" "Gitea ${opts[52]}" "PhpMyAdmin ${opts[53]}" "Wazuh Server ${opts[54]}" "Wazuh Agent ${opts[55]}"
    "Passbolt CE ${opts[56]}" "Done ${opts[57]}")
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
            "Python ${opts[3]}")
                choice 3
                break
                ;;
            "WineHQ Latest ${opts[4]}")
                choice 4
                break
                ;;
            "FFmpeg ${opts[5]}")
                choice 5
                break
                ;;
            "Apache ${opts[6]}")
                choice 6
                break
                ;;
            "Transmission ${opts[7]}")
                choice 7
                break
                ;;
            "Nmap ${opts[8]}")
                choice 8
                break
                ;;
            "Nginx ${opts[9]}")
                choice 9
                break
                ;;
            "Redis ${opts[10]}")
                choice 10
                break
                ;;
            "OpenSSL ${opts[11]}")
                choice 11
                break
                ;;
            "OpenSSH ${opts[12]}")
                choice 12
                break
                ;;
            "GoCD ${opts[13]}")
                choice 13
                break
                ;;
            "OpenJDK 8-11-17 ${opts[14]}")
                choice 14
                break
                ;;
            "DVBlast 3.4 ${opts[15]}")
                choice 15
                break
                ;;
            "Linux Kernel ${opts[16]}")
                choice 16
                break
                ;;
            "Samba ${opts[17]}")
                choice 17
                break
                ;;
            "Mysql ${opts[18]}")
                choice 18
                break
                ;;
            "Mysql Router ${opts[19]}")
                choice 19
                break
                ;;
            "Ruby ${opts[20]}")
                choice 20
                break
                ;;
            "Flutter ${opts[21]}")
                choice 21
                break
                ;;
            "Zabbix Server ${opts[22]}")
                choice 22
                break
                ;;
            "UrBackup Server ${opts[23]}")
                choice 23
                break
                ;;
            "MariaDB ${opts[24]}")
                choice 24
                break
                ;;
            "PostgreSQL ${opts[25]}")
                choice 25
                break
                ;;
            "Postman ${opts[26]}")
                choice 26
                break
                ;;
            "Docker ${opts[27]}")
                choice 27
                break
                ;;
            "Jenkins ${opts[28]}")
                choice 28
                break
                ;;
            "Nodejs & Npm ${opts[29]}")
                choice 29
                break
                ;;
            "Tinc ${opts[30]}")
                choice 30
                break
                ;;
            "Irssi ${opts[31]}")
                choice 31
                break
                ;;
            "OpenNebula ${opts[32]}")
                choice 32
                break
                ;;
            "Links ${opts[33]}")
                choice 33
                break
                ;;
            "MongoDB ${opts[34]}")
                choice 34
                break
                ;;
            "Ansible ${opts[35]}")
                choice 35
                break
                ;;
            "ClamAV ${opts[36]}")
                choice 36
                break
                ;;
            "Graylog ${opts[37]}")
                choice 37
                break
                ;;
            "VLC ${opts[38]}")
                choice 38
                break
                ;;
            "UFW ${opts[39]}")
                choice 39
                break
                ;;
            "Fail2ban ${opts[40]}")
                choice 40
                break
                ;;
            "Google Authenticator ${opts[41]}")
                choice 41
                break
                ;;
            "Composer ${opts[42]}")
                choice 42
                break
                ;;
            "Podman ${opts[43]}")
                choice 43
                break
                ;;
            "NFS Server ${opts[44]}")
                choice 44
                break
                ;;
            "Elasticsearch ${opts[45]}")
                choice 45
                break
                ;;
            "Kibana ${opts[46]}")
                choice 46
                break
                ;;
            "pgAdmin ${opts[47]}")
                choice 47
                break
                ;;
            "pgAgent ${opts[48]}")
                choice 48
                break
                ;;
            "Zabbix Agent ${opts[49]}")
                choice 49
                break
                ;;
            "Enterprise Search ${opts[50]}")
                choice 50
                break
                ;;
            "Logstash ${opts[51]}")
                choice 51
                break
                ;;
            "Gitea ${opts[52]}")
                choice 52
                break
                ;;
            "PhpMyAdmin ${opts[53]}")
                choice 53
                break
                ;;
            "Wazuh Server ${opts[54]}")
                choice 54
                break
                ;;
            "Wazuh Agent ${opts[55]}")
                choice 55
                break
                ;;
            "Passbolt CE ${opts[56]}")
                choice 56
                break
                ;;
            "Done ${opts[57]}")
                break 2
                ;;
            *) printf '%s\n' 'Please Choose Between 1-57';;
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


#Necessary Packages Installation
if [[ $(yum repolist | grep -qi "codeready-builder-for-rhel") ]];then
    :
else
    sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
fi
#sudo subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"
sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -vy install yum-utils dnf-utils
sudo dnf -vy install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
sudo dnf -vy install wget curl mlocate nano lynx net-tools git iftop htop snapd bash-completion make cmake \
bind-utils iotop powertop atop bzip2 bzip2-devel bzip2-libs redhat-lsb-core mc unzip wget
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
export PATH=$PATH:/snap/bin
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
            #3-Python
            . "$scripts_path/3-Python.sh"
            ;;
            4)
            #4-WineHQ
            . "$scripts_path/4-Winehq.sh"
            ;;
            5)
            #5-FFmpeg
            . "$scripts_path/5-Ffmpeg.sh"
            ;;
            6)
            #6-Apache
            . "$scripts_path/6-Apache.sh"
            ;;
            7)
            #7-Transmission
            . "$scripts_path/7-Transmission.sh"
            ;;
            8)
            #8-Nmap
            . "$scripts_path/8-Nmap.sh"
            ;;
            9)
            #9-Nginx
            . "$scripts_path/9-Nginx.sh"
            ;;
            10)
            #10-Redis
            . "$scripts_path/10-Redis.sh"
            ;;
            11)
            #11-OpenSSL
            . "$scripts_path/10-Openssl.sh"
            ;;
            12)
            #12-Openssh
            . "$scripts_path/12-Openssh.sh"
            ;;
            13)
            #13-Gocd
            . "$scripts_path/13-Gocd.sh"
            ;;
            14)
            #14-Openjdk
            . "$scripts_path/14-Openjdk.sh"
            ;;
            15)
            #15-Dvblast
            . "$scripts_path/15-Dvblast.sh"
            ;;
            16)
            #16-Linux-Kernel
            . "$scripts_path/16-Linux-Kernel.sh"
            ;;
            17)
            #17-Samba
            . "$scripts_path/17-Samba.sh"
            ;;
            18)
            #18-Mysql
            . "$scripts_path/18-Mysql.sh"
            ;;
            19)
            #19-Mysql-Router
            . "$scripts_path/19-Mysql-Router.sh"
            ;;
            20)
            #20-Ruby
            . "$scripts_path/20-Ruby.sh"
            ;;
            21)
            #21-Flutter
            . "$scripts_path/21-Flutter.sh"
            ;;
            22)
            #22-Zabbix-Server
            . "$scripts_path/22-Zabbix-Server.sh"
            ;;
            23)
            #23-Urbackup-Server
            . "$scripts_path/23-Urbackup-Server.sh"
            ;;
            24)
            #24-Mariadb
            . "$scripts_path/24-Mariadb.sh"
            ;;
            25)
            #25-Postgresql
            . "$scripts_path/25-Postgresql.sh"
            ;;
            26)
            #26-Postman
            . "$scripts_path/26-Postman.sh"
            ;;
            27)
            #27-Docker
            . "$scripts_path/27-Docker.sh"
            ;;
            28)
            #28-Jenkins
            . "$scripts_path/28-Jenkins.sh"
            ;;
            29)
            #29-Nodejs-And-Npm
            . "$scripts_path/29-Nodejs-And-Npm.sh"
            ;;
            30)
            #30-Tinc
            . "$scripts_path/30-Tinc.sh"
            ;;
            31)
            #31-Irssi
            . "$scripts_path/31-Irssi.sh"
            ;;
            32)
            #32-Opennebula
            . "$scripts_path/32-Opennebula.sh"
            ;;
            33)
            #33-Links
            . "$scripts_path/33-Links.sh"
            ;;
            34)
            #34-Mongodb
            . "$scripts_path/34-Mongodb.sh"
            ;;
            35)
            #35-Ansible
            . "$scripts_path/35-Ansible.sh"
            ;;
            36)
            #36-Clamav
            . "$scripts_path/36-Clamav.sh"
            ;;
            37)
            #37-Graylog
            . "$scripts_path/37-Graylog.sh"
            ;;
            38)
            #38-Vlc
            . "$scripts_path/38-Vlc.sh"
            ;;
            39)
            #39-Ufw
            . "$scripts_path/39-Ufw.sh"
            ;;
            40)
            #40-Fail2ban
            . "$scripts_path/40-Fail2ban.sh"
            ;;
            41)
            #41-Google-Authenticator
            . "$scripts_path/41-Google-Authenticator.sh"
            ;;
            42)
            #42-Composer
            . "$scripts_path/42-Composer.sh"
            ;;
            43)
            #43-Podman
            . "$scripts_path/43-Podman.sh"
            ;;
            44)
            #44-Nfs-Server
            . "$scripts_path/44-Nfs-Server.sh"
            ;;
            45)
            #45-Elasticsearch
            . "$scripts_path/45-Elasticsearch.sh"
            ;;
            46)
            #46-Kibana
            . "$scripts_path/46-Kibana.sh"
            ;;
            47)
            #47-PgAdmin
            . "$scripts_path/47-Pgadmin.sh"
            ;;
            48)
            #48-Pgagent
            . "$scripts_path/48-Pgagent.sh"
            ;;
            49)
            #49-Zabbix-Agent
            . "$scripts_path/49-Zabbix-Agent.sh"
            ;;
            50)
            #50-Enterprise-Search
            . "$scripts_path/50-Enterprise-Search.sh"
            ;;
            51)
            #51-Logstash
            . "$scripts_path/51-Logstash.sh"
            ;;
            52)
            #52-Gitea
            . "$scripts_path/52-Gitea.sh"
            ;;
            53)
            #53-Phpmyadmin
            . "$scripts_path/53-Phpmyadmin.sh"
            ;;
            54)
            #54-Wazuh-Server
            . "$scripts_path/54-Wazuh-Server.sh"
            ;;
            55)
            #55-Wazuh-Agent
            . "$scripts_path/55-Wazuh-Agent.sh"
            ;;
            56)
            #56-Passbolt CE
            . "$scripts_path/56-Passbolt-Ce.sh"
            ;;
        esac
    fi
done