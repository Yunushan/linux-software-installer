#!/usr/bin/env bash
MODULE_ID='firewalld'
MODULE_NAME='firewalld'
MODULE_DESCRIPTION='Dynamic firewall management service for RHEL-family systems'
MODULE_CATEGORY='security'
MODULE_FAMILIES=(rhel)
MODULE_RHEL_PACKAGES=(firewalld)
MODULE_RHEL_SERVICES=(firewalld)
MODULE_VERIFY_BINARIES=(firewall-cmd)
MODULE_NOTES='No ports or services are opened automatically.'
