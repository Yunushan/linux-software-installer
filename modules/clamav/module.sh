#!/usr/bin/env bash
MODULE_ID='clamav'
MODULE_NAME='ClamAV'
MODULE_DESCRIPTION='Open-source antivirus scanner from Debian-family repositories'
MODULE_CATEGORY='security'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(clamav clamav-daemon)
MODULE_VERIFY_BINARIES=(clamscan)
MODULE_NOTES='Signature updates and daemon configuration remain administrator-controlled.'
