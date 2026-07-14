#!/bin/bash

#20-Kubectl
sudo snap remove kubectl
printf "\nPlease Choose Your Desired kubectl Version\n\n1-)Kubectl \n2-)Kubectl (Snap)\n3-)Kubectl (Binary)\n\n\
Please Select Your Kubectl Version:"
read -r kubectlversion
if [ "$kubectlversion" = "1" ];then
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo dnf -vy install kubelet kubeadm kubectl 
sudo systemctl start kubelet 
sudo systemctl enable kubelet
printf "\n"
kubectl version
elif [ "$kubectlversion" = "2" ];then
    sudo dnf -vy remove kubelet kubeadm kubectl
    sudo snap install kubectl --classic
elif [ "$kubectlversion" = "3" ];then
    sudo snap remove kubectl
    sudo dnf -vy remove kubelet kubeadm kubectl
    cd /root/Downloads
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
    echo "Out of options please choose between 1-3"
    :
fi
printf "\nKubectl Installation Has Finished\n\n"