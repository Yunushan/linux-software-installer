#!/bin/bash

#27-VMware Workstation Pro
wget -O /root/Downloads/VMware-Workstation-Pro.bundle https://www.vmware.com/go/getworkstation-linux
sudo yum install gcc kernel-devel kernel-headers -y
sudo yum groupinstall 'Development Tools' -y
sudo bash /root/Downloads/VMware-Workstation-Pro.bundle