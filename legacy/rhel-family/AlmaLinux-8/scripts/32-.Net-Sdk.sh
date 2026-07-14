#!/bin/bash

#32-.NET SDK
printf "\nPlease Choose Your Desired .NET SDK Version\n\n1-).NET SDK 2.1\n2-).NET SDK 3.0\n\
3-).NET SDK 3.1\n4-).NET SDK 5.0\n5-).NET SDK 6.0\n\nPlease Select Your Nodejs Version:"
read -r netsdkversion
if [ "$netsdkversion" = "1" ];then
    sudo dnf -vy remove dotnet*
    sudo dnf -vy install dotnet-sdk-2.1
elif [ "$netsdkversion" = "2" ];then
    sudo dnf -vy remove dotnet*
    sudo dnf -vy install dotnet-sdk-3.0
elif [ "$netsdkversion" = "3" ];then
    sudo dnf -vy remove dotnet*
    sudo dnf -vy install dotnet-sdk-3.1
elif [ "$netsdkversion" = "4" ];then
    sudo dnf -vy remove dotnet*
    sudo dnf -vy install dotnet-sdk-5.0
elif [ "$netsdkversion" = "5" ];then
    sudo dnf -vy remove dotnet*
    sudo dnf -vy install dotnet-sdk-6.0
else
    echo "Out of options please choose between 1-4"  
fi