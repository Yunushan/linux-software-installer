#!/bin/bash

#25-OpenSSL
printf "\nPlease Choose Your Desired OpenSSL Version\n\n1-)OpenSSL 1.1.1 (Official Package)\n\
2-)OpenSSL Latest (Compile From Source)\n\nPlease Select Your OpenSSL Version:"
read -r opensslversion
if [ "$opensslversion" = "1" ];then
    sudo install openssl-devel -y
elif [ "$opensslversion" = "2" ];then
sudo dnf -vy install perl gcc
openssl_latest=$(lynx -dump https://www.openssl.org/source/ | awk '{print $2}' | grep -iv '.asc\|sha\|fips' \
| grep -i .tar.gz | tail -n 1)
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
    :
fi
printf "\nOpenSSL Installation Has Finished \n\n"