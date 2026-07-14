#!/bin/bash

#29-Fail2ban
sudo dnf -vy install fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
echo "[sshd]
enabled = true
port = ssh
action = iptables-multiport
logpath = /var/log/secure
maxretry = 5
bantime = 60" > /etc/fail2ban/jail.d/sshd.local
sudo systemctl restart fail2ban