#!/bin/bash

# 5-Linux-Kernel
printf "\nPlease Choose Your Desired Kernel Version\n\n1-)Mainline Kernel (Latest)\n\
2-)Longterm Kernel (LTS)\n\nPlease Select Your Linux Kernel Version:"
read -r kernelversion
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo dnf -vy install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm

if [ "$kernelversion" = "1" ];then
    sudo dnf -vy --enablerepo=elrepo-kernel install kernel-ml
elif [ "$kernelversion" = "2" ];then
    sudo dnf -vy --enablerepo=elrepo-kernel install kernel-lt
else
    echo "Out of options please choose between 1-2"
fi
grub2-set-default 0
grub2-mkconfig -o /etc/grub2.cfg
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
#grubby --set-default /boot/vmlinuz-5.16.2-1.el8.elrepo.x86_64
#sudo dnf -vy update kernel # To Update Linux Kernel
printf "\nLinux Kernel Installation Has Finished To Apply New Kernel Please Reboot The Server.\n\n"