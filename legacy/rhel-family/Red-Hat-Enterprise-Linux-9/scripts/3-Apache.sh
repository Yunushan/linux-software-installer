#!/bin/bash

#3-Apache2
printf "\nPlease Choose Your Desired Apache Version\n\n1-) Apache (From Official Package)\n\
2-) Apache Latest(Compile From Source)\n3-) Apache Latest (From .rpm file with default spec file)\n\
4-) Apache Latest (From .rpm file with custom .spec file only --prefix=/etc/httpd added)\
\n\nPlease Select Your Apache Version:"
read -r apacheversion
if [ "$apacheversion" = "1" ];then
    sudo dnf -vy install apache2
    sudo systemctl start httpd
    sudo systemctl enable httpd
elif [ "$apacheversion" = "2" ];then
    apache_latest=$(lynx -dump https://dlcdn.apache.org//httpd | awk '{print $2}' | grep -iv '.asc\|.sha' \
    | grep -i .tar.gz | tail -n 1)
    sudo dnf -vy install apr-devel apr-util apr-util-devel gcc pcre-devel make cmake redhat-rpm-config
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
    ./configure --enable-ssl \
                --enable-so \
                --with-mpm=event \
                --with-included-apr \
                --enable-mods-shared=all \
                --prefix=/usr/local/apache
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
ln -s /usr/local/apache/bin/httpd /usr/sbin/httpd
systemctl enable httpd
systemctl start httpd

elif [ "$apacheversion" = "3" ];then
    sudo dnf -vy remove httpd
    sudo mkdir -pv /root/Downloads/httpd
    wget -O /root/Downloads/httpd/httpd-2.4.54.tar.bz2 https://dlcdn.apache.org//httpd/httpd-2.4.54.tar.bz2
    sudo dnf -vy install autoconf libuuid-devel lua \
    libxml2-devel apr apr-util apr-util-devel \
    perl make cmake gcc rpm-build rpmdevtools rpmlint pcre-devel libselinux-devel
    sudo dnf -vy install https://rpmfind.net/linux/centos-stream/9-stream/CRB/x86_64/os/Packages/lua-devel-5.4.2-4.el9.x86_64.rpm
    rpmdev-setuptree
    cd /root/Downloads/httpd
    rpmbuild -tb httpd-2.4.54.tar.bz2
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/httpd-2.4.54-1.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/mod_ssl-2.4.54-1.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/httpd-devel-2.4.54-1.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/httpd-tools-2.4.54-1.x86_64.rpm
    systemctl enable httpd
    systemctl start httpd
elif [ "$apacheversion" = "4" ];then
    sudo dnf -vy remove httpd
    sudo dnf -vy install rpm-build rpmdevtools rpmlint openssl-devel
    rpmdev-setuptree
    sudo mkdir -pv /root/rpmbuild/SOURCES/httpd-2.4.54
    wget -O /root/rpmbuild/SOURCES/httpd-2.4.54.tar.bz2 https://dlcdn.apache.org//httpd/httpd-2.4.54.tar.bz2
    tar -xvf /root/rpmbuild/SOURCES/httpd-2.4.54.tar.bz2 -C /root/rpmbuild/SOURCES/httpd-2.4.54 --strip-components 1
    sudo dnf -vy install autoconf libuuid-devel lua \
    libxml2-devel apr apr-util apr-util-devel \
    perl make cmake gcc rpm-build rpmdevtools rpmlint pcre-devel libselinux-devel
    sudo dnf -vy install https://rpmfind.net/linux/centos-stream/9-stream/CRB/x86_64/os/Packages/lua-devel-5.4.2-4.el9.x86_64.rpm
    sudo cp -v /root/rpmbuild/SOURCES/httpd-2.4.54/httpd.spec /root/rpmbuild/SPECS/
    grep -qxF '        --prefix=/etc/httpd \' /root/rpmbuild/SPECS/httpd.spec || \
    sudo sed -i '/--enable-case-filter/a \ \ \ \ \ \ \ \ --prefix=/etc/httpd \\' /root/rpmbuild/SPECS/httpd.spec
    rpmbuild -ba /root/rpmbuild/SPECS/httpd.spec
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/httpd-2.4.54-1.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/mod_ssl-2.4.54-1.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/httpd-devel-2.4.54-1.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/httpd-tools-2.4.54-1.x86_64.rpm
    systemctl enable httpd
    systemctl start httpd
else
    echo "Out of options please choose between 1-4"
fi

sudo systemctl daemon-reload
sudo systemctl enable httpd
sudo systemctl start httpd
sudo dnf -vy install apachetop

#sudo firewall-cmd --zone=public --permanent --add-service=http
#sudo firewall-cmd --zone=public --permanent --add-service=https
#sudo firewall-cmd --reload
printf "\nApache2 Installation Has Finished\n\n"
