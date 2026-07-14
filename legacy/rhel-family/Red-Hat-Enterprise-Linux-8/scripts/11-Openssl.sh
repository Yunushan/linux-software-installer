#!/bin/bash

#11-OpenSSL
#OpenSSL Installation Section
printf "\nPlease Choose Your Desired OpenSSL Version\n\n1-)OpenSSL 1.1.1k (Official Package)\n2-)OpenSSL 3.0\n\
3-)OpenSSL 3 Latest(Compile From Source)\n4-)OpenSSL 1 Latest (Compile From Source)\n\
5-)OpenSSL 1.1.1n (Create & Install .rpm file From .spec)\n\
6-)OpenSSL 3.0.2 (.rpm file from .spec)\n\nPlease Select Your OpenSSL Version:\n\nPlease Select Your OpenSSL Version:"

read -r opensslversion
if [ "$opensslversion" = "1" ];then
    sudo dnf -vy install openssl-devel
elif [ "$opensslversion" = "2" ];then
    sudo dnf -vy install openssl3 openssl3-devel openssl3-libs
elif [ "$opensslversion" = "3" ];then
    sudo rm -rf /root/Downloads/openssl-latest
    sudo dnf -vy install perl gcc
    openssl_latest=$(lynx -dump https://www.openssl.org/source/ | awk '{print $2}' | grep -iv '.asc\|sha\|fips'\
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
elif [ "$opensslversion" = "4" ];then
    #sudo dnf -vy remove openssl openssl-devel
    sudo rm -rf /root/Downloads/openssl-latest
    sudo dnf -vy group install 'Development Tools'
    sudo dnf -vy install perl gcc
    openssl_latest=$(lynx -dump https://www.openssl.org/source/ | awk '{print $2}' | grep -iv '.asc\|sha\|fips' \
    | grep -i openssl-1 | head -n 1)
    wget -O /root/Downloads/openssl-latest.tar.gz "$openssl_latest"
    sudo mkdir -pv /root/Downloads/openssl-latest
    tar -xvf /root/Downloads/openssl-latest.tar.gz -C /root/Downloads/openssl-latest --strip-components 1
    cd /root/Downloads/openssl-latest
    ./config #--prefix=/usr         \
         #--openssldir=/etc/ssl \
         #--libdir=lib          \
         #shared                \
         #zlib-dynamic
    make -j "$core" && make -j "$core" install
    echo "export PATH="/usr/local/ssl/bin:"${PATH}""" >> ~/.bashrc
    source /root/.bashrc
    #ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    #ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
elif [ "$opensslversion" = "5" ];then
    sudo dnf -vy install curl which make gcc perl perl-WWW-Curl rpm-build rpmdevtools rpmlint
    rpmdev-setuptree
    sudo dnf -vy remove openssl openssl-devel
    wget -O /root/rpmbuild/SOURCES/openssl-1.1.1o.tar.gz https://www.openssl.org/source/openssl-1.1.1o.tar.gz
cat << 'EOF' > /root/rpmbuild/SPECS/openssl.spec
Summary: OpenSSL 1.1.1o for RedHat
Name: openssl
Version: %{?version}%{!?version:1.1.1o}
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
OpenSSL RPM for version 1.1.1o on RedHat
%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}
%description devel
OpenSSL RPM for version 1.1.1o on RedHat (development package)
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
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-1.1.1o-1.el8.x86_64.rpm --nodeps --force
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-devel-1.1.1o-1.el8.x86_64.rpm
elif [ "$opensslversion" = "6" ];then
    sudo dnf -vy install curl which make gcc perl perl-WWW-Curl rpm-build rpmdevtools rpmlint
    rpmdev-setuptree
    wget -O /root/rpmbuild/SOURCES/openssl-3.0.3.tar.gz https://www.openssl.org/source/openssl-3.0.3.tar.gz
    sudo dnf -vy remove openssl openssl-devel
    cat << 'EOF' > /root/rpmbuild/SPECS/openssl.spec
Summary: OpenSSL 3.0.3 for Red Hat
Name: openssl
Version: %{?version}%{!?version:3.0.3}
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
OpenSSL RPM for version 3.0.3 on Red Hat

%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
OpenSSL RPM for version 3.0.3 on Red Hat (development package)

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
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-3.0.3-1.el8.x86_64.rpm --nodeps
    sudo rpm -Uvh /root/rpmbuild/RPMS/x86_64/openssl-devel-3.0.3-1.el8.x86_64.rpm
    ln -s /usr/openssl/lib64/libssl.so.3 /usr/lib64/libssl.so.3
    ln -s /usr/openssl/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
    ln -s /usr/openssl/bin/openssl /usr/bin/openssl
else
    echo "Out of options please choose between 1-6"
fi
printf "\nOpenSSL Installation Has Finished \n\n"