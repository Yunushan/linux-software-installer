#!/bin/bash

#35-Visual Studio Code
printf "\nPlease Choose Your Desired Visual Studio Code Version \n\n1-)Visual Studio Code(From Package Manager)\n\
2-)Visual Studio Code (Via Snap)\n\nPlease Select Your Visual Studio Code Version:"
read -r visual_studio_code_version
if [ "$visual_studio_code_version" = "1" ];then
    sudo snap remove code
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\n\
    gpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf -vy install code
elif [ "$visual_studio_code_version" = "2" ];then
    sudo dnf -vy remove code
    sudo snap install code --classic
else
    echo "Out of options please choose between 1-2"
fi