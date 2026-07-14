#!/bin/bash

#43-.NET SDK
printf "\nPlease Choose Your Desired .NET SDK Version\n\n1-).NET SDK 2.1\n2-).NET SDK 2.2\n3-).NET SDK 3.0 \n4-).NET SDK 3.1\n5-).NET SDK 5.0\n6-).NET SDK 6.0\n\nPlease Select Your .NET SDK Version:"
read -r netsdkversion
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
if [ "$netsdkversion" = "1" ];then
    sudo yum remove dotnet* -y
    sudo yum install dotnet-sdk-2.1 -y
elif [ "$netsdkversion" = "2" ];then
    sudo yum remove dotnet* -y
    sudo yum install dotnet-sdk-2.2 -y
elif [ "$netsdkversion" = "3" ];then
    sudo yum remove dotnet* -y
    sudo yum install dotnet-sdk-3.0 -y
elif [ "$netsdkversion" = "4" ];then
    sudo yum remove dotnet* -y
    sudo yum install dotnet-sdk-3.1 -y
elif [ "$netsdkversion" = "5" ];then
    sudo yum remove dotnet* -y
    sudo yum install dotnet-sdk-5.0 -y
elif [ "$netsdkversion" = "6" ];then
    sudo yum remove dotnet* -y
    sudo yum install dotnet-sdk-6.0 -y
else
    echo "Out of options please choose between 1-6"  
fi