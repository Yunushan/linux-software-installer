#!/usr/bin/env bash
MODULE_ID='samba'
MODULE_NAME='Samba'
MODULE_DESCRIPTION='SMB/CIFS file and print services'
MODULE_CATEGORY='server'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(samba smbclient)
MODULE_RHEL_PACKAGES=(samba samba-client)
MODULE_DEBIAN_SERVICES=(smbd)
MODULE_RHEL_SERVICES=(smb)
MODULE_VERIFY_BINARIES=(smbclient)
MODULE_NOTES='No shares, users, firewall rules or SELinux policies are changed.'
