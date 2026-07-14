#!/usr/bin/env bash
MODULE_ID='ufw'
MODULE_NAME='Uncomplicated Firewall'
MODULE_DESCRIPTION='Firewall management frontend for Debian-family systems'
MODULE_CATEGORY='security'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(ufw)
MODULE_VERIFY_BINARIES=(ufw)
MODULE_NOTES='The firewall is installed but never enabled and no rules are added.'
