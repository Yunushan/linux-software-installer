#!/bin/bash

#55-Wazuh-Agent

rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
WAZUH_MANAGER="10.0.0.2" yum install wazuh-agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo