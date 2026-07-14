#!/bin/bash

#17-pgAdmin
sudo rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-2-1.noarch.rpm
sudo dnf -vy install pgadmin4
sudo /usr/pgadmin4/bin/setup-web.sh