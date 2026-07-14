#!/bin/bash

#33-Jitsi
sudo mkdir -pv /root/Downloads/
jitsi_link=$(lynx -dump https://desktop.jitsi.org/Main/Download | awk '/http/{print $2}' | grep -i .rpm | head -n 1)
sudo wget -O /root/Downloads/latest-jitsi.rpm "$jitsi_link"
sudo wget -O /root/Downloads/speex-1.2-0.23.rc2.el7.centos.x86_64.rpm https://copr-be.cloud.fedoraproject.org/results/fedpop/speex/epel-7-x86_64/00146973-speex/speex-1.2-0.23.rc2.el7.centos.x86_64.rpm
sudo rpm -i speex-1.2-0.23.rc2.el7.centos.x86_64.rpm
sudo wget -O /root/Downloads/speexdsp-1.2-0.7.rc3.el7.centos.x86_64.rpm https://copr-be.cloud.fedoraproject.org/results/fedpop/speexdsp/epel-7-x86_64/00146970-speexdsp/speexdsp-1.2-0.7.rc3.el7.centos.x86_64.rpm
sudo rpm -i speexdsp-1.2-0.7.rc3.el7.centos.x86_64.rpm
sudo rpm -i /root/Downloads/latest-jitsi.rpm