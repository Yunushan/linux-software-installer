#!/bin/bash

# 10-Openssl
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