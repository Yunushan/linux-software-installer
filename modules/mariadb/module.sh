#!/usr/bin/env bash
MODULE_ID='mariadb'
MODULE_NAME='MariaDB Server'
MODULE_DESCRIPTION='MariaDB database server from the OS repository'
MODULE_CATEGORY='database'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(mariadb-server mariadb-client)
MODULE_RHEL_PACKAGES=(mariadb-server mariadb)
MODULE_DEBIAN_SERVICES=(mariadb)
MODULE_RHEL_SERVICES=(mariadb)
MODULE_VERIFY_BINARIES=(mariadb)
MODULE_CONFLICTS=(mysql)
MODULE_NOTES='Existing databases are never deleted or initialized by this module.'
