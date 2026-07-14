#!/bin/bash

#10-Redis
printf "\nPlease Choose Your Desired Redis Version\n\n1-)Redis (Official Package)\n2-)Redis (Snap)\n\
3-)Redis (Compile From Source)\n4-)Redis (.rpm file)\n\nPlease Select Your Redis Version:"
read -r redis_version
if [ "$redis_version" = "1" ];then
    sudo snap remove redis
    cd /root/Downloads/redis-stable
    make -j "$core" uninstall
    sudo dnf -vy install redis redis-devel
    sudo systemctl enable --now redis
    sudo systemctl start redis
    sudo firewall-cmd --add-port=6379/tcp --permanenent
    sudo firewall-cmd --reload
elif [ "$redis_version" = "2" ];then
    sudo dnf -vy remove redis redis-devel
    cd /root/Downloads/redis-stable
    make -j "$core" uninstall
    sudo snap install redis
elif [ "$redis_version" = "3" ];then
    sudo snap remove redis
    sudo dnf -vy remove redis redis-devel
    sudo mkdir -pv /root/Downloads/redis-stable
    wget -O /root/Downloads/redis-stable.tar.gz http://download.redis.io/redis-stable.tar.gz
    tar -xvf /root/Downloads/redis-stable.tar.gz -C /root/Downloads/redis-stable --strip-components 1
    cd /root/Downloads/redis-stable
    make -j "$core" && make -j "$core" install
elif [ "$redis_version" = "4" ];then
    redis_stable_link=$(lynx -dump https://download.redis.io/releases/ | awk '/http/ {print $2}' \
    | grep -iv 'rc\|beta\|stable\|scripting' | tail -n 1)
    redis_stable_version_number=$(lynx -dump https://download.redis.io/releases/ | awk '/http/ {print $2}' \
    | grep -iv 'rc\|beta\|stable\|scripting' | tail -n 1 | grep -E -o "[0-9].{0,4}")
    sudo dnf -vy install rpm-build rpmdevtools rpmlint logrotate chkconfig initscripts shadow-utils
cat << 'EOF' > /root/rpmbuild/SPECS/redis.spec
# Check for status of man pages
# http://code.google.com/p/redis/issues/detail?id=202

Name:             redis
Version:          6.2.6
Release:          1%{?dist}
Summary:          A persistent key-value database

Group:            Applications/Databases
License:          BSD
URL:              http://redis.io
Source0:          http://redis.googlecode.com/files/%{name}-%{version}.tar.gz
Source1:          %{name}.logrotate
Source2:          %{name}.init
# Update configuration
#Patch0:           %{name}-%{version}-redis.conf.patch
BuildRoot:        %{_tmppath}/%{name}-%{version}-root-%(%{__id_u} -n)

ExcludeArch:      ppc ppc64

Requires:         logrotate
Requires(post):   chkconfig
Requires(postun): initscripts
Requires(pre):    shadow-utils
Requires(preun):  chkconfig
Requires(preun):  initscripts

%description
Redis is an advanced key-value store. It is similar to memcached but the data
set is not volatile, and values can be strings, exactly like in memcached, but
also lists, sets, and ordered sets. All this data types can be manipulated with
atomic operations to push/pop elements, add/remove elements, perform server side
union, intersection, difference between sets, and so forth. Redis supports
different kind of sorting abilities.

%prep
%setup -q
#%patch0 -p1

%build
make %{?_smp_mflags} \
  DEBUG='' \
  CFLAGS='%{optflags}' \
  V=1 \
  all

%install
rm -fr %{buildroot}
make install PREFIX=%{buildroot}%{_prefix}
# Install misc other
install -p -D -m 644 %{SOURCE1} %{buildroot}%{_sysconfdir}/logrotate.d/%{name}
install -p -D -m 755 %{SOURCE2} %{buildroot}%{_initrddir}/%{name}
install -p -D -m 644 %{name}.conf %{buildroot}%{_sysconfdir}/%{name}.conf
install -d -m 755 %{buildroot}%{_localstatedir}/lib/%{name}
install -d -m 755 %{buildroot}%{_localstatedir}/log/%{name}
install -d -m 755 %{buildroot}%{_localstatedir}/run/%{name}

# Fix non-standard-executable-perm error
chmod 755 %{buildroot}%{_bindir}/%{name}-*

# Ensure redis-server location doesn't change
mkdir -p %{buildroot}%{_sbindir}
mv %{buildroot}%{_bindir}/%{name}-server %{buildroot}%{_sbindir}/%{name}-server

%clean
rm -fr %{buildroot}

%post
/sbin/chkconfig --add redis

%pre
getent group redis &> /dev/null || groupadd -r redis &> /dev/null
getent passwd redis &> /dev/null || \
useradd -r -g redis -d %{_localstatedir}/lib/redis -s /sbin/nologin \
-c 'Redis Server' redis &> /dev/null
exit 0

%preun
if [ $1 = 0 ]; then
  /sbin/service redis stop &> /dev/null
  /sbin/chkconfig --del redis &> /dev/null
fi

%files
%defattr(-,root,root,-)
%doc 00-RELEASENOTES BUGS CONTRIBUTING COPYING README
%config(noreplace) %{_sysconfdir}/logrotate.d/%{name}
%config(noreplace) %{_sysconfdir}/%{name}.conf
%dir %attr(0755, redis, root) %{_localstatedir}/lib/%{name}
%dir %attr(0755, redis, root) %{_localstatedir}/log/%{name}
%dir %attr(0755, redis, root) %{_localstatedir}/run/%{name}
%{_bindir}/%{name}-*
%{_sbindir}/%{name}-*
%{_initrddir}/%{name}
EOF
    wget -O /root/rpmbuild/SOURCES/redis-6.2.6.tar.gz https://download.redis.io/releases/redis-6.2.6.tar.gz
    rpmbuild -ba /root/rpmbuild/SPECS/redis.spec
else
    echo "Out of options please choose between 1-3"
fi