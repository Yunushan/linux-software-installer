#!/bin/bash

#49-Zabbix Agent
printf "\nPlease Choose Your Desired Zabbix Agent Version\n\n1-) Zabbix Agent (6.0 LTS)\n\
2-) Zabbix Agent (5.0 LTS)\n3-) Zabbix Agent (4.0 LTS)\n\nPlease Select Your Zabbix Agent Version:"
read -r zabbix_agent_version
if [ "$elasticsearch_version" = "1" ];then
    rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-1.el8.noarch.rpm
    sudo dnf -vy install zabbix-agent
    sudo systemctl enable zabbix-agent.service
    sudo systemctl start zabbix-agent.service
elif [ "$elasticsearch_version" = "2" ];then
    rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    sudo dnf -vy install zabbix-agent
    sudo systemctl enable zabbix-agent.service
    sudo systemctl start zabbix-agent.service
elif [ "$elasticsearch_version" = "3" ];then
    rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/8/x86_64/zabbix-release-4.0-2.el8.noarch.rpm
    sudo dnf -vy install zabbix-agent
    sudo systemctl enable zabbix-agent.service
    sudo systemctl start zabbix-agent.service
else
    echo "Out of options please choose between 1-3"
fi