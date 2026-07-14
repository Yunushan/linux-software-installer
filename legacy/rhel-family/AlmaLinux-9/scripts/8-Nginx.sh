#!/bin/bash

#OpenSSL Installation Section
openssl1_1_latest_name=$(lynx -dump https://www.openssl.org/source/ | awk '/http/{print $2}' | grep -iv 'sha\|asc' | grep -i tar.gz | sed 's/.......$//' \
| cut -c 40-50 | grep 1.1.1 | head -n 1)
openssl3_0_latest_name=$(lynx -dump https://www.openssl.org/source/ | awk '/http/{print $2}' | grep -iv 'sha\|asc' | grep -i tar.gz | sed 's/.......$//' \
| cut -c 40-50 | grep 3.0 | head -n 1)
openssl3_1_latest_name=$(lynx -dump https://www.openssl.org/source/ | awk '/http/{print $2}' | grep -iv 'sha\|asc' | grep -i tar.gz | sed 's/.......$//' \
| cut -c 40-50 | grep 3.1 | head -n 1)
printf "\nPlease Choose Your Desired OpenSSL Version\n\n1-)OpenSSL 3 (Official Package)\n\
2-)OpenSSL $openssl3_1_latest_name (Compile From Source)\n\
3-)OpenSSL $openssl3_1_latest_name (.rpm file from .spec)\n\
4-)OpenSSL $openssl1_1_latest_name (Compile From Source)\n\
5-)OpenSSL $openssl1_1_latest_name (Create & Install .rpm file from .spec)\n\
6-)OpenSSL $openssl3_0_latest_name (.rpm file from .spec)\n\nPlease Select Your OpenSSL Version:"
read -r opensslversion
if [ "$opensslversion" = "1" ];then
    sudo dnf -vy install openssl openssl-devel openssl-libs
elif [ "$opensslversion" = "2" ];then
    sudo rm -rf /root/Downloads/openssl-latest
    sudo dnf -vy install perl gcc
    openssl3_1_latest=$(lynx -dump https://www.openssl.org/source/ | awk '{print $2}' | grep -iv '.asc\|sha\|fips'\
    | grep -i .tar.gz | tail -n 1)
    wget -O /root/Downloads/openssl-latest.tar.gz "$openssl3_1_latest"
    sudo mkdir -pv /root/Downloads/openssl-latest
    tar -xvf /root/Downloads/openssl-latest.tar.gz -C /root/Downloads/openssl-latest --strip-components 1
    cd /root/Downloads/openssl-latest
    ./config
    make -j "$core" && make -j "$core" install
    echo "export PATH="/usr/local/ssl/bin:"${PATH}""" >> ~/.bashrc
    ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
elif [ "$opensslversion" = "3" ];then
sudo dnf -vy install curl which make gcc perl perl-WWW-Curl rpm-build rpmdevtools rpmlint
    rpmdev-setuptree
    wget -O /root/rpmbuild/SOURCES/openssl-3.1.1.tar.gz https://www.openssl.org/source/openssl-3.1.1.tar.gz
    sudo dnf -vy remove openssl openssl-devel
    cat << 'EOF' > /root/rpmbuild/SPECS/openssl.spec
Summary: OpenSSL 3.1 for Red Hat
Name: openssl
Version: %{?version}%{!?version:3.1.1}
Release: 1%{?dist}
Obsoletes: %{name} <= %{version}
Provides: %{name} = %{version}
URL: https://www.openssl.org/
License: GPLv2+

Source: https://www.openssl.org/source/%{name}-%{version}.tar.gz

BuildRequires: make gcc perl perl-WWW-Curl
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%global openssldir /usr/openssl

%description
https://github.com/philyuchkoff/openssl-RPM-Builder
OpenSSL RPM for version "3.1 on Red Hat

%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
OpenSSL RPM for version 3.1 on Red Hat (development package)

%prep
%setup -q

%build
./config --prefix=%{openssldir} --openssldir=%{openssldir}
make

%install
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%make_install

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libssl.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libcrypto.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/bin/openssl %{buildroot}%{_bindir}

%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}

%files
%{openssldir}
%defattr(-,root,root)

%files devel
%{openssldir}/include/*
%defattr(-,root,root)

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig
%define _unpackaged_files_terminate_build 0
EOF
    cd /root/rpmbuild/SPECS && \
    rpmbuild \
    -D 'debug_package %{nil}' \
    -ba openssl.spec
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-3.1.1-1.el9.x86_64.rpm --nodeps
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-devel-3.1.1-1.el8.x86_64.rpm
    ln -s /usr/openssl/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    ln -s /usr/openssl/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
    ln -s /usr/openssl/bin/openssl /usr/bin/openssl
elif [ "$opensslversion" = "4" ];then
 #sudo dnf -vy remove openssl openssl-devel
    sudo rm -rf /root/Downloads/openssl-latest
    sudo dnf -vy group install 'Development Tools'
    sudo dnf -vy install perl gcc
    openssl3_1_latest=$(lynx -dump https://www.openssl.org/source/ | awk '{print $2}' | grep -iv '.asc\|sha\|fips' \
    | grep -i openssl-1 | head -n 1)
    wget -O /root/Downloads/openssl-latest.tar.gz "$openssl3_1_latest"
    sudo mkdir -pv /root/Downloads/openssl-latest
    tar -xvf /root/Downloads/openssl-latest.tar.gz -C /root/Downloads/openssl-latest --strip-components 1
    cd /root/Downloads/openssl-latest
    ./config
    make -j "$core" && make -j "$core" install
    echo "export PATH="/usr/local/ssl/bin:"${PATH}""" >> ~/.bashrc
    source /root/.bashrc
    #ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    #ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
elif [ "$opensslversion" = "5" ];then
    sudo dnf -vy install curl which make gcc perl perl-WWW-Curl rpm-build rpmdevtools rpmlint
    rpmdev-setuptree
    sudo dnf -vy remove openssl openssl-devel
    wget -O /root/rpmbuild/SOURCES/openssl-1.1.1u.tar.gz https://www.openssl.org/source/openssl-1.1.1u.tar.gz
cat << 'EOF' > /root/rpmbuild/SPECS/openssl.spec
Summary: OpenSSL 1.1.1u for RedHat
Name: openssl
Version: %{?version}%{!?version:1.1.1u}
Release: 1%{?dist}
Obsoletes: %{name} <= %{version}
Provides: %{name} = %{version}
URL: https://www.openssl.org/
License: GPLv2+
Source: https://www.openssl.org/source/%{name}-%{version}.tar.gz
BuildRequires: make gcc perl perl-WWW-Curl
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%global openssldir /usr/openssl
%description
https://github.com/philyuchkoff/openssl-RPM-Builder
OpenSSL RPM for version 1.1.1u on RedHat
%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}
%description devel
OpenSSL RPM for version 1.1.1u on RedHat (development package)
%prep
%setup -q
%build
./config --prefix=%{openssldir} --openssldir=%{openssldir}
make %{?_smp_mflags}
%install
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%make_install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libssl.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libcrypto.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/bin/openssl %{buildroot}%{_bindir}
%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%files
%{openssldir}
%defattr(-,root,root)
/usr/bin/openssl
/usr/lib64/libcrypto.so.1.1
/usr/lib64/libssl.so.1.1
%files devel
%{openssldir}/include/*
%defattr(-,root,root)
%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig
EOF
    cd /root/rpmbuild/SPECS && \
        rpmbuild \
        -D 'debug_package %{nil}' \
        -ba openssl.spec
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-1.1.1u-1.el9.x86_64.rpm --nodeps --force
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-devel-1.1.1u-1.el9.x86_64.rpm
elif [ "$opensslversion" = "6" ];then
    sudo dnf -vy install curl which make gcc perl perl-WWW-Curl rpm-build rpmdevtools rpmlint
    rpmdev-setuptree
    wget -O /root/rpmbuild/SOURCES/openssl-3.0.9.tar.gz https://www.openssl.org/source/openssl-3.0.9.tar.gz
    sudo dnf -vy remove openssl openssl-devel
    cat << 'EOF' > /root/rpmbuild/SPECS/openssl.spec
Summary: OpenSSL 3.0.9 for Red Hat
Name: openssl
Version: %{?version}%{!?version:3.0.9}
Release: 1%{?dist}
Obsoletes: %{name} <= %{version}
Provides: %{name} = %{version}
URL: https://www.openssl.org/
License: GPLv2+

Source: https://www.openssl.org/source/%{name}-%{version}.tar.gz

BuildRequires: make gcc perl perl-WWW-Curl
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%global openssldir /usr/openssl

%description
https://github.com/philyuchkoff/openssl-RPM-Builder
OpenSSL RPM for version 3.0.9 on Red Hat

%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
OpenSSL RPM for version 3.0.9 on Red Hat (development package)

%prep
%setup -q

%build
./config --prefix=%{openssldir} --openssldir=%{openssldir}
make

%install
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%make_install

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libssl.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libcrypto.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/bin/openssl %{buildroot}%{_bindir}

%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}

%files
%{openssldir}
%defattr(-,root,root)

%files devel
%{openssldir}/include/*
%defattr(-,root,root)

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig
%define _unpackaged_files_terminate_build 0
EOF
    cd /root/rpmbuild/SPECS && \
    rpmbuild \
    -D 'debug_package %{nil}' \
    -ba openssl.spec
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-3.0.9-1.el9.x86_64.rpm --nodeps
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-devel-3.0.9-1.el8.x86_64.rpm
    ln -s /usr/openssl/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    ln -s /usr/openssl/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
    ln -s /usr/openssl/bin/openssl /usr/bin/openssl
else
    echo "Out of options please choose between 1-6"
fi
#2-Nginx
printf "\nPlease Choose Your Desired Nginx Version\n\n1-) Nginx (Official Package)\n\
2-) Nginx Latest(Compile From Source)\n3-) Nginx (Compile .src.rpm File)\n4-) Nginx (From .rpm file)\n\
5-) Nginx (From nginx.repo Stable)\n6-) Nginx (From nginx.repo Mainline)\nPlease Select Your Nginx Version:"
read -r nginx_version

if [ "$nginx_version" = "1" ];then
    sudo dnf -vy instal nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
elif [ "$nginx_version" = "2" ];then
    sudo dnf -vy install gd gd-devel pcre-devel
    nginx_latest=$(lynx -dump http://nginx.org/en/download.html | awk '{print $2}' | grep -iv '.asc\|.zip' \
    | grep -i .tar.gz | head -n 1)
    sudo mkdir -pv /root/Downloads/nginx_latest /var/www/html
    wget -O /root/Downloads/nginx_latest.tar.gz "$nginx_latest"
    tar -xvf /root/Downloads/nginx_latest/nginx_latest.tar.gz -C /root/Downloads/nginx_latest --strip-components 1
    cd /root/Downloads/nginx_latest
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
    sudo systemctl start nginx
    sudo systemctl enable nginx
elif [ "$nginx_version" = "3" ];then
    sudo dnf -vy install yum-utils rpmdevtools rpm-build rpmdevtools rpmlint spectool
    sudo dnf -vy groupinstall "Development Tools"
    rpmdev-setuptree
    nginx_latest_source_rpm=$(lynx -dump http://nginx.org/packages/rhel/9/SRPMS/ | awk '/http/ {print $2}' \
    | grep -iv 'perl\|njs\|xslt\|image-filter\|repodata' | grep -i el9.ngx.src.rpm | tail -n 1)
    sudo mkdir -pv /root/Downloads
    wget -O /root/Downloads/nginx-latest.ngx.src.rpm "$nginx_latest_source_rpm"
    sudo rpm -Uvh /root/Downloads/nginx-latest.ngx.src.rpm
    sudo yum-builddep -vy /root/Downloads/nginx-latest.ngx.src.rpm
    sudo rpmbuild -v --rebuild /root/Downloads/nginx-latest.ngx.src.rpm
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/nginx-*
    sudo systemctl start nginx
    sudo systemctl enable nginx
elif [ "$nginx_version" = "4" ];then
    nginx_latest_rpm=$(lynx -dump http://nginx.org/packages/rhel/9/x86_64/RPMS/ | awk '/http/ {print $2}' \
    | grep -iv 'perl\|njs\|xslt\|image-filter\|repodata\|debuginfo' | grep -i .el9.ngx.x86_64.rpm | tail -n 1)
    sudo mkdir -pv /root/Downloads
    wget -O /root/Downloads/nginx-latest.rpm "$nginx_latest_rpm"
    sudo rpm -Uvh /root/Downloads/nginx-latest.rpm
    sudo systemctl start nginx
    sudo systemctl enable nginx
elif [ "$nginx_version" = "5" ];then
    sudo dnf -vy install yum-utils
    echo "[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/rhel/9/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/rhel/9/x86_64/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true" > /etc/yum.repos.d/nginx.repo
    sudo yum-config-manager -v --disable nginx-mainline
    sudo yum-config-manager -v --enable nginx-stable
    sudo dnf -vy install nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx

elif [ "$nginx_version" = "6" ];then
    sudo dnf -vy install yum-utils
    echo "[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/rhel/9/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/rhel/9/x86_64/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true" > /etc/yum.repos.d/nginx.repo
    sudo yum-config-manager -v --disable nginx-stable
    sudo yum-config-manager -v --enable nginx-mainline
    sudo dnf -vy install nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
else
    echo "Out of option Please Choose between 1-6"
fi
printf "\nNginx installation Has Finished\n\n"