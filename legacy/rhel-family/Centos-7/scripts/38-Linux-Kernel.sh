#!/bin/bash

#38-Linux Kernel
printf "\nPlease Choose Your Desired Kernel Version\n\n1-)Mainline Kernel (Latest)\n2-)Longterm Kernel (LTS)\n\nPlease Select Your Linux Kernel Version:"
read -r kernelversion
if [ "$kernelversion" = "1" ];then
    sudo yum --enablerepo=elrepo-kernel install kernel-ml -y
elif [ "$kernelversion" = "2" ];then
    sudo yum --enablerepo=elrepo-kernel install kernel-lt -y
else
    echo "Out of options please choose between 1-2"
fi
grub2-set-default 0
grub2-mkconfig -o /etc/grub2.cfg
sudo yum install bash-completion -y
#sudo yum update kernel -y # To Update Linux Kernel
printf "\nLinux Kernel Installation Has Finished To Apply New Kernel Please Reboot The Server.\n\n"