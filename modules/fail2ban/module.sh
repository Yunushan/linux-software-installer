#!/usr/bin/env bash
MODULE_ID='fail2ban'
MODULE_NAME='Fail2ban'
MODULE_DESCRIPTION='Log-driven intrusion prevention service'
MODULE_CATEGORY='security'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(fail2ban)
MODULE_DEBIAN_SERVICES=(fail2ban)
MODULE_VERIFY_BINARIES=(fail2ban-client)
MODULE_NOTES='No jail is enabled or changed automatically.'
