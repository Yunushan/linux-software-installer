#!/usr/bin/env bash
MODULE_ID='nginx'
MODULE_NAME='Nginx'
MODULE_DESCRIPTION='Nginx web and reverse-proxy server from the OS repository'
MODULE_CATEGORY='server'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(nginx)
MODULE_RHEL_PACKAGES=(nginx)
MODULE_DEBIAN_SERVICES=(nginx)
MODULE_RHEL_SERVICES=(nginx)
MODULE_VERIFY_BINARIES=(nginx)
MODULE_CONFLICTS=(apache)
MODULE_NOTES='Does not replace OpenSSL, add third-party repositories or open firewall ports.'
