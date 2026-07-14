#!/bin/bash

#41-Google Authenticator
printf "\nPlease Choose Your Desired Google Authenticator Version\n1-)Google Authenticator(From Official Package)\n\
2-)Google Authenticator (Compile From Source)\n\
3-)Google Authenticator (From .rpm file)\n\nPlease Select Your Google Authenticator Version:"
read -r google_authenticator_version
if [ "$google_authenticator_version" = "1" ];then
    cd /root/Downloads/google-authenticator-libpam
    make -j "$core" uninstall
    sudo dnf -vy install google-authenticator qrencode qrencode-libs wget make gcc pam-devel
    grep -qxF 'auth required pam_google_authenticator.so nullok' /etc/pam.d/sshd || \
    echo 'auth required pam_google_authenticator.so nullok' >> /etc/pam.d/sshd
    grep -qxF 'auth required pam_permit.so' /etc/pam.d/sshd || echo 'auth required pam_permit.so' >> /etc/pam.d/sshd
    sed -ie 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
elif [ "$google_authenticator_version" = "2" ];then
    sudo mkdir -pv /root/Downloads/google-authenticator-libpam
    sudo dnf -vy remove google-authenticator
    sudo dnf -vy install wget make gcc pam-devel automake libtool gcc git
    git clone https://github.com/google/google-authenticator-libpam.git /root/Downloads/google-authenticator-libpam
    cd /root/Downloads/google-authenticator-libpam
    chmod +x /root/Downloads/google-authenticator-libpam/bootstrap.sh
    ./bootstrap.sh
    ./configure
    make -j "$core" && make -j "$core" install
    grep -qxF 'auth required pam_google_authenticator.so nullok' /etc/pam.d/sshd || \
    echo 'auth required pam_google_authenticator.so nullok' >> /etc/pam.d/sshd
    grep -qxF 'auth required pam_permit.so' /etc/pam.d/sshd || echo 'auth required pam_permit.so' >> /etc/pam.d/sshd
    sed -ie 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
elif [ "$google_authenticator_version" = "3" ];then
    sudo dnf -vy remove google-authenticator
    sudo dnf -vy install rpm-build rpmdevtools rpmlint wget make gcc pam-devel automake libtool gcc git
    rpmdev-setuptree
    google_authenticator_latest=$(lynx -dump https://github.com/google/google-authenticator-libpam/tags \
    | awk '/http/ {print $2}' | grep -i tar.gz | head -n 1)
    sudo mkdir -pv /root/rpmbuild/SOURCES/google-authenticator
    sudo wget -O /root/rpmbuild/SOURCES/google-authenticator-latest.tar.gz "$google_authenticator_latest"
    tar -xvf /root/rpmbuild/SOURCES/google-authenticator-latest.tar.gz -C /root/rpmbuild/SOURCES/google-authenticator --strip-components 1
    cd /root/rpmbuild/SOURCES/google-authenticator/contrib
    ./build-rpm.sh stable
    rpm -Uvh /root/rpmbuild/SOURCES/google-authenticator/contrib/_rpmbuild/RPMS/x86_64/google-authenticator-*
else
    echo "Out of options please choose between 1-3"
fi