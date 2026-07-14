#!/bin/bash

#33-OpenSSH Server
printf "\nPlease Choose Your Desired OpenSSH Version \n\n1-)OpenSSH Server (Official Package)\n\
2-)OpenSSH Latest (Compile From Source)\n\nPlease Select Your OpenSSH Version:"
read -r opensshversion
if [ "$opensshversion" = "1" ];then
    cd /root/Downloads/openssh-latest
    make -j "$core" uninstall
    sudo dnf -vy install openssh openssh-clients openssh-server 
elif [ "$opensshversion" = "2" ];then
    #sudo dnf -vy remove openssh*
    sudo dnf -vy install gcc zlib zlib-devel compat-openssl10 openssl openssl-devel
    sudo dnf -vy group install 'Development Tools'
    sudo dnf -vy install zlib-devel openssl-devel pam-devel libselinux-devel
    sudo dnf -vy install audit-libs-devel autoconf automake gcc libX11-devel libselinux-devel make \
    ncurses-devel openssl-devel p11-kit-devel perl-generators systemd-devel xauth pam-devel rpm-build zlib-devel
    #sudo mkdir /var/lib/sshd
    #sudo chmod -R 700 /var/lib/sshd/
    #sudo chown -R root:sys /var/lib/sshd/
    #sudo useradd -r -U -d /var/lib/sshd/ -c "sshd privsep" -s /bin/false sshd
    sudo mkdir -pv /root/Downloads/openssh-latest
    opensshlatest=$(lynx -dump https://www.openssh.com/releasenotes.html | awk '/http/{print $2}' \
    | grep -i p1.tar.gz | head -n 1)
    wget -O /root/Downloads/openssh-latest.tar.gz $opensshlatest
    tar -xvf /root/Downloads/openssh-latest.tar.gz -C /root/Downloads/openssh-latest --strip-components 1
    cd /root/Downloads/openssh-latest
    ./configure --with-md5-passwords \
                --with-pam \
                --with-selinux \
                --with-privsep-path=/opt/lib/sshd/ \
                --sysconfdir=/opt/ssh
    make -j "$core" && make -j "$core" install
    systemctl restart sshd
else
    echo "Out of options please choose between 1-2"  
fi