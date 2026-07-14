#!/bin/bash

#48-pgAgent
sudo dnf -vy install boost-system boost-filesystem boost-atomic boost-chrono boost-thread boost-date-time
sudo rpm -Uvh https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8-x86_64/pgagent_14-4.2.1-1.rhel8.x86_64.rpm
sudo systemctl enable pgagent_14.service
sudo systemctl start pgagent_14.service