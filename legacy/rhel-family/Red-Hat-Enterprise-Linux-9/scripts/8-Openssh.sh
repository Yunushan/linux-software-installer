#!/bin/bash

# 8-OpenSSH

printf "\nPlease Choose Your Desired OpenSSH Version \n\n1-)OpenSSH Server (Official Package)\n\
2-)OpenSSH Latest (Compile From Source)\n3-)OpenSSH Latest (With .rpm File)\nPlease Select Your OpenSSH Version:"
read -r opensshversion
if [ "$opensshversion" = "1" ];then
    cd /root/Downloads/openssh-latest
    make -j "$core" uninstall
    sudo dnf -vy install openssh openssh-clients openssh-server
elif [ "$opensshversion" = "2" ];then
    #sudo dnf -vy remove openssh openssh-clients openssh-server
    sudo dnf -vy install gcc zlib zlib-devel compat-openssl10 openssl openssl-devel zlib-devel openssl-devel pam-devel \
    libselinux-devel audit-libs-devel autoconf automake gcc libX11-devel libselinux-devel make ncurses-devel \
    openssl-devel p11-kit-devel perl-generators systemd-devel xauth pam-devel rpm-build zlib-devel
    sudo dnf -vy group install 'Development Tools'
    #sudo mkdir /var/lib/sshd
    #sudo chmod -R 700 /var/lib/sshd/
    #sudo chown -R root:sys /var/lib/sshd/
    #sudo useradd -r -U -d /var/lib/sshd/ -c "sshd privsep" -s /bin/false sshd
    sudo mkdir -pv /root/Downloads/openssh-latest
    opensshlatest=$(lynx -dump https://www.openssh.com/releasenotes.html | awk '/http/{print $2}' \
    | grep -i p1.tar.gz | head -n 1)
    wget -O /root/Downloads/openssh-latest.tar.gz "$opensshlatest"
    tar -xvf /root/Downloads/openssh-latest.tar.gz -C /root/Downloads/openssh-latest --strip-components 1
    cd /root/Downloads/openssh-latest
    ./configure --with-md5-passwords \
                --with-pam \
                --with-selinux \
                --with-privsep-path=/opt/lib/sshd/ \
                --sysconfdir=/opt/ssh
    make -j "$core" && make -j "$core" install
    sed -i -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
    sed -i -e "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
    sed -i -e "s/#UsePAM no/UsePAM yes/g" /etc/ssh/sshd_config
    systemctl restart sshd
elif [ "$opensshversion" = "3" ];then
    sudo dnf -vy install gcc zlib zlib-devel compat-openssl10 openssl openssl-devel zlib-devel openssl-devel pam-devel \
    libselinux-devel audit-libs-devel autoconf automake gcc libX11-devel libselinux-devel make ncurses-devel \
    openssl-devel p11-kit-devel perl-generators systemd-devel xauth pam-devel rpm-build zlib-devel \
    rpm-build rpmdevtools rpmlint gtk2-devel imake libXt-devel openssl-devel perl
    rpmdev-setuptree
    sudo dnf -vy group install 'Development Tools'
    #opensshlatest=$(lynx -dump https://www.openssh.com/releasenotes.html | awk '/http/{print $2}' \
    #| grep -i p1.tar.gz | head -n 1)
    sudo mkdir -pv /root/rpmbuild/SOURCES/openssh-9.0p1
    sudo mkdir -pv /root/rpmbuild/SPECS
    wget -O /root/rpmbuild/SOURCES/openssh-9.0p1.tar.gz \
    https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.0p1.tar.gz #"$opensshlatest"
    wget -O /root/rpmbuild/SOURCES/x11-ssh-askpass-1.2.4.1.tar.gz \
    https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz
    tar -xvf /root/rpmbuild/SOURCES/openssh-9.0p1.tar.gz -C /root/rpmbuild/SOURCES/openssh-9.0p1 --strip-components 1
    sudo cp -v /root/rpmbuild/SOURCES/openssh-9.0p1/contrib/redhat/openssh.spec /root/rpmbuild/SPECS/openssh.spec
    sed -i -e "s/BuildRequires: openssl-devel >= 1.0.1/#BuildRequires: openssl-devel >= 1.0.1/g" /root/rpmbuild/SPECS/openssh.spec
    sed -i -e "s/BuildRequires: openssl-devel < 1.1/#BuildRequires: openssl-devel < 1.1/g" /root/rpmbuild/SPECS/openssh.spec
    rpmbuild -ba /root/rpmbuild/SPECS/openssh.spec
    sudo dnf -vy remove openssh openssh-clients openssh-server
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/openssh-9.0p1-1.el8.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/openssh-clients-9.0p1-1.el8.x86_64.rpm
    sudo dnf -vy install /root/rpmbuild/RPMS/x86_64/openssh-server-9.0p1-1.el8.x86_64.rpm
    sudo dnf -vy install git
    sed -i -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
    sed -i -e "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
    sed -i -e "s/#UsePAM no/UsePAM yes/g" /etc/ssh/sshd_config
    chmod 600 /etc/ssh/ssh_host_rsa_key
    chmod 600 /etc/ssh/ssh_host_ecdsa_key
    chmod 600 /etc/ssh/ssh_host_ed25519_key
echo "#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_sepermit.so
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin" > /etc/pam.d/sshd
    sudo mkdir -pv /etc/ssh/ssh_config.d/
    echo "# The options here are in the "Match final block" to be applied as the last
# options and could be potentially overwritten by the user configuration
Match final all
        # Follow system-wide Crypto Policy, if defined:
        Include /etc/crypto-policies/back-ends/openssh.config

        GSSAPIAuthentication yes

# If this option is set to yes then remote X11 clients will have full access
# to the original X11 display. As virtually no X11 client supports the untrusted
# mode correctly we set this to yes.
        ForwardX11Trusted yes

# Send locale-related environment variables
        SendEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
        SendEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
        SendEnv LC_IDENTIFICATION LC_ALL LANGUAGE
        SendEnv XMODIFIERS

# Uncomment this if you want to use .local domain
# Host *.local
"> /etc/ssh/ssh_config.d/05-redhat.conf
   sed -i -e "s/#Port 22/Port 22/g" /etc/ssh/sshd_config
   sed -i -e "s/#HostKey \\/etc\\/ssh\\/ssh_host_rsa_key/HostKey \\/etc\\/ssh\\/ssh_host_rsa_key/g" /etc/ssh/sshd_config
   sed -i -e "s/#HostKey \\/etc\\/ssh\\/ssh_host_ecdsa_key/HostKey \\/etc\\/ssh\\/ssh_host_ecdsa_key/g" /etc/ssh/sshd_config
   sed -i -e "s/#HostKey \\/etc\\/ssh\\/ssh_host_ed25519_key/HostKey \\/etc\\/ssh\\/ssh_host_ed25519_key/g" /etc/ssh/sshd_config
   sed -i -e "s/#SyslogFacility AUTH/SyslogFacility AUTHPRIV/g" /etc/ssh/sshd_config
   echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
   sed -i -e "s/#GSSAPIAuthentication no/GSSAPIAuthentication yes/g" /etc/ssh/sshd_config
   sed -i -e "s/#GSSAPICleanupCredentials yes/GSSAPICleanupCredentials no/g" /etc/ssh/sshd_config
   sed -i -e "s/#X11Forwarding no/X11Forwarding yes/g" /etc/ssh/sshd_config
   sed -i -e "s/#PrintMotd yes/PrintMotd no/g" /etc/ssh/sshd_config
   echo "	AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS" >> /etc/ssh/sshd_config
    grep -qxF 'Include /etc/ssh/ssh_config.d/*.conf' /etc/ssh/ssh_config \
    || echo 'Include /etc/ssh/ssh_config.d/*.conf' >> /etc/ssh/ssh_config
    systemctl restart sshd
else
    echo "Out of options please choose between 1-3"
fi