#!/usr/bin/env bash
MODULE_ID='mysql'
MODULE_NAME='MySQL Server'
MODULE_DESCRIPTION='MySQL database server from RHEL-family repositories'
MODULE_CATEGORY='database'
MODULE_FAMILIES=(rhel)
MODULE_RHEL_PACKAGES=(mysql-server mysql)
MODULE_RHEL_SERVICES=(mysqld)
MODULE_VERIFY_BINARIES=(mysqld mysql)
MODULE_CONFLICTS=(mariadb)
MODULE_NOTES='Installs the supported distribution stream; it does not add MySQL Community repositories, select obsolete versions or change credentials.'
