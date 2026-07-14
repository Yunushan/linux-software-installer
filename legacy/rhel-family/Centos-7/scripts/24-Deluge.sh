#!/bin/bash

#24-DELUGE
sudo wget -O /root/Downloads/nux-dextop-release-0-5.el7.nux.noarch.rpm http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
sudo rpm -ivh /root/Downloads/nux-dextop-release-0-5.el7.nux.noarch.rpm
sudo yum install deluge-console -y