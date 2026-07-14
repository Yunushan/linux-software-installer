#!/bin/bash

#8-Apache2
printf "\nPlease Choose Your Desired Apache Version\n\n1-)Apache 2.4.37(From Official Package)\n2-)Apache Latest(Compile From Source)\n\nPlease Select Your Apache Version:"
read -r apacheversion
if [ "$apacheversion" = "1" ];then
    sudo install apache2 -y
elif [ "$apacheversion" = "2" ];then
    apache_latest=$(lynx -dump https://dlcdn.apache.org//httpd | awk '{print $2}' | grep -iv '.asc\|.sha' | grep -i .tar.gz | tail -n 1)
    yum install apr-devel apr-util apr-util-devel gcc pcre-devel make cmake redhat-rpm-config -y
    mkdir -pv /root/Downloads
    mkdir -pv /usr/local/apache
    wget -O /root/Downloads/httpd-latest.tar.gz "$apache_latest"
    mkdir -pv /root/Downloads/httpd-latest
    tar -xvf /root/Downloads/httpd-latest.tar.gz -C /root/Downloads/httpd-latest --strip-components 1

    wget -O /root/Downloads/apr-1.7.0.tar.gz https://dlcdn.apache.org//apr/apr-1.7.0.tar.gz
    mkdir -pv /root/Downloads/apr-1.7.0
    tar -xvf /root/Downloads/apr-1.7.0.tar.gz -C /root/Downloads/apr-1.7.0 --strip-components 1
    mkdir -pv /root/Downloads/httpd-latest/srclib/apr
    cp -rf /root/Downloads/apr-1.7.0/* /root/Downloads/httpd-latest/srclib/apr 

    wget -O /root/Downloads/apr-util-1.6.1.tar.gz https://dlcdn.apache.org//apr/apr-util-1.6.1.tar.gz
    mkdir -pv /root/Downloads/apr-util-1.6.1
    tar -xvf /root/Downloads/apr-util-1.6.1.tar.gz -C /root/Downloads/apr-util-1.6.1 --strip-components 1
    mkdir -pv /root/Downloads/httpd-latest/srclib/apr-util
    cp -rf /root/Downloads/apr-util-1.6.1/* /root/Downloads/httpd-latest/srclib/apr-util

    cd /root/Downloads/httpd-latest
    ./configure --enable-ssl --enable-so --with-mpm=event --with-included-apr --prefix=/usr/local/apache
    make -j "$core" && make -j "$core" install

    echo "[Unit]
Description=The Apache HTTP Server

[Service]
Type=forking
ExecStart=/usr/local/apache/bin/apachectl start
ExecReload=/usr/local/apache/bin/apachectl graceful
ExecStop=/usr/local/apache/bin/apachectl stop
PrivateTmp=true


[Install]
WantedBy=multi-user.target" > /etc/systemd/system/httpd.service

    echo "pathmunge /usr/local/apache/bin" > /etc/profile.d/httpd.sh
else
    echo "Out of options please choose between 1-2"
fi
sudo systemctl daemon-reload
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl status httpd
#sudo firewall-cmd --zone=public --permanent --add-service=http
#sudo firewall-cmd --zone=public --permanent --add-service=https
#sudo firewall-cmd --reload
printf "\nApache2 Installation Has Finished\n\n"