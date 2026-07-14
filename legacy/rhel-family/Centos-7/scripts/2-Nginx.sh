#!/bin/bash

#2-NGINX

#OpenSSL Installation Section
printf "\nPlease Choose Your Desired OpenSSL Version\n\n1-)OpenSSL 1.0.2k (Official Package)\n2-)OpenSSL Latest(Compile From Source)\n\nPlease Select Your OpenSSL Version:"
read -r opensslversion
if [ "$opensslversion" = "1" ];then
    sudo yum -y install openssl openssl-devel
elif [ "$opensslversion" = "2" ];then
    sudo yum install perl gcc -y
    openssl_latest=$(lynx -dump https://www.openssl.org/source/ | awk '{print $2}' | grep -iv '.asc\|sha\|fips' | grep -i .tar.gz | tail -n 1)
    wget -O /root/Downloads/openssl-latest.tar.gz "$openssl_latest"
    sudo mkdir -pv /root/Downloads/openssl-latest
    tar -xvf /root/Downloads/openssl-latest.tar.gz -C /root/Downloads/openssl-latest --strip-components 1
    cd /root/Downloads/openssl-latest
    ./config
    make -j "$core" && make -j "$core" install
    echo "export PATH="/usr/local/ssl/bin:"${PATH}""" >> ~/.bashrc
    ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
else
    echo "Out of options please choose between 1-2"
fi
#----------------------------------------------------------------------------------------
#Nginx installation section
printf "\nPlease Choose Your Desired Nginx Version\n\n1-)Nginx (Official Package)\n2-)Nginx Latest(Compile From Source)\n\nPlease Select Your Nginx Version:"
read -r nginxversion
if [ "$nginxversion" = "1" ];then
    yum install nginx -y
elif [ "$nginxversion" = "2" ];then
    sudo yum install gd gd-devel pcre-devel -y
    nginx_latest=$(lynx -dump http://nginx.org/en/download.html | awk '{print $2}' | grep -iv '.asc\|.zip' | grep -i .tar.gz | head -n 1)
    mkdir -pv /root/Downloads/nginx-latest
    wget -O /root/Downloads/nginx-latest/nginx-latest.tar.gz "$nginx_latest"
    tar -xvf /root/Downloads/nginx-latest/nginx-latest.tar.gz -C /root/Downloads/nginx-latest --strip-components 1
    cd /root/Downloads/nginx-latest
    ./configure --prefix=/var/www/html --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --with-pcre  \
    --lock-path=/var/lock/nginx.lock --pid-path=/var/run/nginx.pid --with-http_ssl_module \
    --with-http_image_filter_module=dynamic --modules-path=/etc/nginx/modules --with-http_v2_module \
    --with-stream=dynamic --with-http_addition_module --with-http_mp4_module
    make -j "$core" && make -j "$core" install
    echo "[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/nginx.service
else
    echo "Out of options please choose between 1-2"
    :
fi
#------------------------------------------------------------
sudo systemctl enable nginx
sudo systemctl start nginx
#sudo firewall-cmd --permanent --zone=public --add-service=http 
#sudo firewall-cmd --permanent --zone=public --add-service=https
#sudo firewall-cmd --reload

printf "\nNginx Installation Has Finished\n\n"