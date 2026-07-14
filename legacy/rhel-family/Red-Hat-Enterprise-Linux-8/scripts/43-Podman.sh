#!/bin/bash

#43-Podman
printf "\nPlease Choose Your Desired Podman Version\n1-)Podman(From Official Package)\n\
2-)Podman (Compile From Source)\n\
3-)Podman (Via Nix)\n4-)Podman (Via Ansible)\n\nPlease Select Your Podman Version:"
read -r podman_version
if [ "$podman_version" = "1" ];then
    sudo dnf -vy install @container-tools
elif [ "$podman_version" = "2" ];then
    #Install Necessary Packages
    sudo dnf -vy install conmon containernetworking-plugins containers-common crun \
    device-mapper-devel git glib2-devel glibc-devel glibc-static go golang-github-cpuguy83-md2man gpgme-devel \
    iptables libassuan-devel libgpg-error-devel libseccomp-devel libselinux-devel make pkgconfig
    #Install go
    export GOPATH=root/Downloads/go
    git clone https://go.googlesource.com/go $GOPATH
    cd $GOPATH
    cd src
    ./all.bash
    export PATH=$GOPATH/bin:$PATH
    #Install Conmon
    git clone https://github.com/containers/conmon
    cd conmon
    export GOCACHE="$(mktemp -d)"
    make -j "$core"
    sudo make -j "$core" podman
    #Install Runc
    git clone https://github.com/opencontainers/runc.git $GOPATH/src/github.com/opencontainers/runc
    cd $GOPATH/src/github.com/opencontainers/runc
    make -j "$core" BUILDTAGS="selinux seccomp"
    sudo cp runc /usr/bin/runc
    #Add configuration
    sudo mkdir -p /etc/containers
    sudo curl -L -o /etc/containers/registries.conf https://src.fedoraproject.org/rpms/containers-common/raw/main/f/registries.conf
    sudo curl -L -o /etc/containers/policy.json https://src.fedoraproject.org/rpms/containers-common/raw/main/f/default-policy.json
    #Install Podman
    git clone https://github.com/containers/podman/
    cd podman
    make -j "$core" BUILDTAGS="selinux seccomp apparmor systemd"
    sudo make -j "$core" install PREFIX=/usr
elif [ "$podman_version" = "3" ];then
    mkdir -p ~/.ansible/roles
    cd ~/.ansible/roles
    git clone https://github.com/alvistack/ansible-role-podman.git podman
    cd ~/.ansible/roles/podman
    pip3 install --upgrade --ignore-installed --requirement requirements.txt
    molecule converge
    molecule verify
else
    echo "Out of options please choose between 1-3"
fi