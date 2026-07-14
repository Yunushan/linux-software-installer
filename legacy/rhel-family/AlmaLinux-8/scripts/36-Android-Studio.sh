#!/bin/bash

#36-Android Studio
printf "\nPlease Choose Your Desired Android Studio Version \n\n1-)Android Studio (From .tar.gz file)\n\
2-)Android Studio (Via Snap)\n\nPlease Select Your Android Studio Version:"
read -r android_studio_version
if [ "$android_studio_version" = "1" ];then
    sudo mkdir -pv /root/Downloads/android-studio
    sudo dnf -vy install java-1.8.0-openjdk java-1.8.0-openjdk-devel
    sudo snap remove android-studio
    android_studio_latest=$(lynx -dump https://developer.android.com/studio | awk '/http/{print $2}' | grep -i .tar.gz | head -n 1)
    wget -O /root/Downloads/android_studio_latest.tar.gz "$android_studio_latest"
    tar xvf /root/Downloads/android_studio_latest.tar.gz -C /root/Downloads/android-studio --strip-components 1
    cd /root/Downloads/android-studio/
    ln -s /root/Downloads/android-studio/bin/studio.sh /usr/local/bin/android-studio
elif [ "$android_studio_version" = "2" ];then
    sudo dnf -vy install java-1.8.0-openjdk java-1.8.0-openjdk-devel
    sudo snap install android-studio --classic
else
    echo "Out of options please choose between 1-2"
fi