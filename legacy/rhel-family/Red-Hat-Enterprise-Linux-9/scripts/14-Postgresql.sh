#!/bin/bash

#14-PostgreSQL
printf "\nPlease Choose Your Desired PostgreSQL Version\n\n1-)PostgreSQL 10\n2-)PostgreSQL 11\n\
3-)PostgreSQL 12\n4-)PostgreSQL 13\n5-)PostgreSQL 14\n\nPlease Select Your PostgreSQL Version:"
read -r postgresql_version
sudo dnf -vy install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -vy module disable postgresql
sudo dnf clean all
if [ "$postgresql_version" = "1" ];then
    sudo dnf -vy install postgresql10-server postgresql10
    sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
    sudo systemctl enable postgresql-10
    sudo systemctl start postgresql-10
elif [ "$postgresql_version" = "2" ];then
    sudo dnf -vy install postgresql11-server postgresql11
    sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
    sudo systemctl enable postgresql-11
    sudo systemctl start postgresql-11
elif [ "$postgresql_version" = "3" ];then
    sudo dnf -vy install postgresql12-server postgresql12
    sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
    sudo systemctl enable postgresql-12
    sudo systemctl start postgresql-12
elif [ "$postgresql_version" = "4" ];then
    sudo dnf -vy install postgresql13-server postgresql13
    sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
    sudo systemctl enable postgresql-13
    sudo systemctl start postgresql-13
elif [ "$postgresql_version" = "5" ];then
    sudo dnf -vy install postgresql14-server postgresql14
    sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
    sudo systemctl enable postgresql-14
    sudo systemctl start postgresql-14
else
    echo "Out of options please choose between 1-5"
fi
