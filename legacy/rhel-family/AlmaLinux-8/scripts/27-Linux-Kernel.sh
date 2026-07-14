#!/bin/bash

#27-Linux Kernel
printf "\nPlease Choose Your Desired Kernel Version\n\n1-)Mainline Kernel (Latest)\n\
2-)Longterm Kernel (LTS)\n\nPlease Select Your Linux Kernel Version:"
read -r kernelversion
if [ "$kernelversion" = "1" ];then
    sudo dnf -vy --enablerepo=elrepo-kernel install kernel-ml
elif [ "$kernelversion" = "2" ];then
    sudo dnf -vy --enablerepo=elrepo-kernel install kernel-lt
else
    echo "Out of options please choose between 1-2"
fi
grub2-set-default 0
grub2-mkconfig -o /etc/grub2.cfg
sudo dnf -vy install bash-completion
#sudo dnf -vy update kernel # To Update Linux Kernel
printf "\nLinux Kernel Installation Has Finished To Apply New Kernel Please Reboot The Server.\n\n"