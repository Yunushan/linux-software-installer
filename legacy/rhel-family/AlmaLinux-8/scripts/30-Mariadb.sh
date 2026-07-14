#!/bin/bash

#30-MariaDB
printf "\nPlease Choose Your Desired MariaDB Version\n\n1-)MariaDB 10.3 (Official Repo)\n\
2-)MariaDB 10.4\n3-)MariaDB 10.5\n4-)MariaDB 10.6\n\nPlease Select Your MariaDB Version:"
read -r mariadbversion
if [ "$mariadbversion" = "1" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.3
    sudo dnf -vy install boost-program-options
    sudo dnf -vy module reset mariadb
    sudo dnf -vy install mariadb mariadb-devel MariaDB-server MariaDB-client MariaDB-backup
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb 
elif [ "$mariadbversion" = "2" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    sudo bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.4
    sudo dnf -vy install boost-program-options
    sudo dnf -vy module reset mariadb
    sudo dnf -vy install MariaDB-server MariaDB-client MariaDB-backup
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb
elif [ "$mariadbversion" = "3" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    sudo bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.5
    sudo dnf -vy install boost-program-options
    sudo dnf -vy module reset mariadb
    sudo dnf -vy install MariaDB-server MariaDB-client MariaDB-backup
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb
elif [ "$mariadbversion" = "4" ];then
    wget -O /root/Downloads/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    sudo bash /root/Downloads/mariadb_repo_setup --mariadb-server-version=10.6
    sudo dnf -vy install boost-program-options
    sudo dnf -vy module reset mariadb
    sudo dnf -vy install MariaDB-server MariaDB-client MariaDB-backup
    sudo systemctl enable --now mariadb
    sudo systemctl start mariadb 
else
    echo "Out of options please choose between 1-4"  
fi