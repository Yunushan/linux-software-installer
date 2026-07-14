#!/usr/bin/env bash
MODULE_ID='php'
MODULE_NAME='PHP runtime'
MODULE_DESCRIPTION='PHP CLI, FPM and common database drivers'
MODULE_CATEGORY='server'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(php-cli php-fpm php-mysql php-pgsql)
MODULE_RHEL_PACKAGES=(php-cli php-fpm php-mysqlnd php-pgsql)
MODULE_RHEL_SERVICES=(php-fpm)
MODULE_VERIFY_BINARIES=(php)
MODULE_NOTES='The Debian-family PHP-FPM service is version-specific and is therefore not auto-enabled.'
