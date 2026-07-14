#!/bin/bash

#28-Samba
printf "\nPlease Choose Your Desired Samba Version\n\n1-)Samba Official\n\
2-)Samba From Compile From Source (Latest)\n\nPlease Select Your Samba Version:"
read -r sambaversion
if [ "$sambaversion" = "1" ];then
    sudo dnf -vy samba samba-common samba-client
    systemctl enable smb
    systemctl start smb
elif [ "$sambaversion" = "2" ];then
    sudo dnf -vy install docbook-style-xsl gcc gdb gnutls-devel gpgme-devel jansson-devel \
      keyutils-libs-devel krb5-workstation libacl-devel libaio-devel \
      libarchive-devel libattr-devel libblkid-devel libtasn1 libtasn1-tools \
      libxml2-devel libxslt lmdb-devel openldap-devel pam-devel perl \
      perl-ExtUtils-MakeMaker perl-Parse-Yapp popt-devel python3-cryptography \
      python3-dns python3-gpg python36-devel readline-devel rpcgen systemd-devel \
      tar zlib-devel
    sudo dnf -vy install dnf-plugins-core cups-devel
    samba_latest=$(lynx -dump https://download.samba.org/pub/samba/ | awk '{print $2}' | grep -i samba-latest.tar.gz | head -n 1)
    wget -O /root/Downloads/samba-latest.tar.gz "$samba_latest"
    sudo mkdir -pv /root/Downloads/samba-latest
    tar -xzvf /root/Downloads/samba-latest.tar.gz -C /root/Downloads/samba-latest --strip-components 1
    cd /root/Downloads/samba-latest
    ./configure --sbindir=/sbin/ \
        --prefix=/usr \
        --enable-fhs \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-privatedir=/var/lib/samba/private \
        --with-smbpasswd-file=/etc/samba/smbpasswd \
        --with-piddir=/var/run/samba \
        --with-pammodulesdir=/lib/x86_64-linux-gnu/security \
        --libdir=/usr/lib/x86_64-linux-gnu \
        --with-modulesdir=/usr/lib/x86_64-linux-gnu/samba \
        --datadir=/usr/share \
        --with-lockdir=/var/run/samba \
        --with-statedir=/var/lib/samba \
        --with-cachedir=/var/cache/samba \
        --with-socketpath=/var/run/ctdb/ctdbd.socket \
        --with-logdir=/var/log/ctdb \
        --systemd-install-services \
        --with-systemd \
        --without-ad-dc
    make -j "$core" && make -j "$core" install
    export PATH=/usr/local/samba/bin/:/usr/local/samba/sbin/:$PATH
    ln -s /root/Downloads/samba-latest/bin/default/packaging/systemd/smb.service /etc/systemd/system/smbd.service
else
    echo "Out of options please choose between 1-2"
fi