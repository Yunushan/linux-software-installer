#!/bin/bash

#4-WineHQ Latest
printf "\nPlease Choose Your Desired Visual Studio Code Version \n\n1-)Visual Studio Code(From Package Manager)\
\n2-)Visual Studio Code (Via Snap)\n\nPlease Select Your Visual Studio Code Version:"
read -r winehq_version
if [ "$winehq_version" = "2" ];then
    sudo dnf -vy install wine wine-common wine-devel winetricks
elif [ "$winehq_version" = "2" ];then
    sudo dnf -vy install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
    sudo mkdir -pv /root/Downloads/winelatest
    wine_latest=$(lynx -dump https://dl.winehq.org/wine/source/ | awk '/http/{print $2}' | grep -iv README | grep wine/source | \
    tail -n 1)
    wine_latest=$(lynx -dump  "$wine_latest" | awk '/http/{print $2}' | grep -i tar.xz | grep -iv sign | tail -n 1)
    sudo dnf -vy groupinstall 'Development Tools'
    sudo dnf -vy install libX11-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel \
    libpng-devel libjpeg-turbo-devel libtiff-devel gstreamer1-devel dbus-devel fontconfig-devel freetype-devel mingw64-cpp \
    mingw64-gcc mingw64-gcc-c++ alsa-plugins-pulseaudio.i686 glibc-devel.i686 glibc-devel libgcc.i686 libX11-devel.i686 \
    freetype-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXext-devel.i686 libXxf86vm-devel.i686 libXrandr-devel.i686 \
    libXinerama-devel.i686 mesa-libGLU-devel.i686 mesa-libOSMesa-devel.i686 libXrender-devel.i686 libpcap-devel.i686 \
    ncurses-devel.i686 libzip libzip-devel libzip-tools lcms2-devel.i686 zlib-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686  \
    cups-devel.i686 libxml2-devel.i686 openldap-devel.i686 libxslt-devel.i686 gnutls-devel.i686 libpng-devel.i686 \
    flac-libs.i686 json-c.i686 libICE.i686 libSM.i686 libXtst.i686 libasyncns.i686 libedit.i686 liberation-narrow-fonts.noarch \
    libieee1284.i686 libogg.i686 libsndfile.i686 libuuid.i686 libva.i686 libvorbis.i686 libwayland-client.i686 \
    libwayland-server.i686 llvm-libs.i686 mesa-dri-drivers.i686 mesa-filesystem.i686 mesa-libEGL.i686 mesa-libgbm.i686 \
    nss-mdns ocl-icd.i686 pulseaudio-libs.i686  sane-backends-libs.i686 tcp_wrappers-libs unixODBC.i686 \
    samba-common-tools.x86_64 samba-libs.x86_64 samba-winbind.x86_64 samba-winbind-clients.x86_64 samba-winbind-modules.x86_64 \
    mesa-libGL-devel.i686 fontconfig-devel.i686 libXcomposite-devel.i686 libtiff-devel.i686 openal-soft-devel.i686 \
    alsa-lib-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 \
    pulseaudio-libs-devel.i686 pulseaudio-libs-devel gtk3-devel.i686 libattr-devel.i686 libva-devel.i686 libexif-devel.i686 \
    libexif.i686 glib2-devel.i686 mpg123-devel.i686 mpg123-devel.x86_64 libcom_err-devel.i686 libcom_err-devel.x86_64 \
    libFAudio-devel.x86_64 gstreamer1-devel gstreamer1-plugins-base gstreamer1-plugins-base-devel.x86_64 \
    gstreamer1-plugins-base-devel.i686 gstreamer1-plugins-bad-free.i686 gstreamer1-plugins-bad-free.x86_64 \
    opencl-filesystem.noarch opencl-headers vkd3d-compiler libvkd3d-utils libvkd3d-utils-devel libvkd3d-devel
    sudo wget -O /root/Downloads/winelatest.tar.xz "$wine_latest"
    tar xvf /root/Downloads/winelatest.tar.xz -C /root/Downloads/winelatest --strip-components 1
    cd /root/Downloads/winelatest/
    ./configure --enable-win64
    make -j "$core" && make -j "$core" install
else
    echo "Out of option Please Choose between 1-2"
fi