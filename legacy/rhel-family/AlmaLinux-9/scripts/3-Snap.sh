#!/bin/bash

#3-Snap From Source Code
sudo dnf -v config-manager --set-enabled crb
sudo dnf -vy install go-toolset
sudo dnf -vy install rpmdevtools
rpmdev-setuptree
snapdstable=$(lynx -dump https://github.com/snapcore/snapd/tags | awk '{print $2}' | grep -v ']' | grep 'tar.gz' | head -n 1)
sudo wget -O /root/Downloads/snapd-latest.tar.gz "$snapdstable"
sudo mkdir -pv /root/Downloads/snapd-latest
tar xzvf /root/Downloads/snapd-latest.tar.gz -C /root/Downloads/snapd-latest --strip-components 1
spectool -g /root/Downloads/snapd-latest/packaging/fedora/snapd.spec
sudo dnf builddep /root/Downloads/snapd-latest/packaging/fedora/snapd.spec -y
rpmbuild -bb /root/Downloads/snapd-latest/packaging/fedora/snapd.spec
snap_confine_rpm=$(locate snap-confine- | grep -i x86_64.rpm | grep -v 'debuginfo' | head -n 1)
snapd_selinux_rpm=$(locate snapd-selinux | head -n 1)
snapd_rpm=$(locate snapd | grep -i x86_64.rpm | grep -v 'debuginfo' | head -n 1)
sudo dnf -vy localinstall "$snap_confine_rpm"
sudo dnf -vy localinstall "$snapd_selinux_rpm"
sudo dnf -vy localinstall "$snapd_rpm"
sudo systemctl enable --now snapd.socket
sleep 5 # For prevent too early operation error on snap
snap install hello-world