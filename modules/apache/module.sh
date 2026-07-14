#!/usr/bin/env bash
MODULE_ID='apache'
MODULE_NAME='Apache HTTP Server'
MODULE_DESCRIPTION='Apache web server from the OS repository'
MODULE_CATEGORY='server'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(apache2)
MODULE_RHEL_PACKAGES=(httpd)
MODULE_DEBIAN_SERVICES=(apache2)
MODULE_RHEL_SERVICES=(httpd)
MODULE_DEBIAN_VERIFY_BINARIES=(apache2ctl)
MODULE_RHEL_VERIFY_BINARIES=(httpd)
MODULE_CONFLICTS=(nginx)
MODULE_NOTES='Service startup is opt-in with --enable-services.'
