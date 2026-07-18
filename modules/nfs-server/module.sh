#!/usr/bin/env bash
MODULE_ID='nfs-server'
MODULE_NAME='NFS server tools'
MODULE_DESCRIPTION='Network File System server utilities'
MODULE_CATEGORY='server'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(nfs-kernel-server)
MODULE_RHEL_PACKAGES=(nfs-utils)
MODULE_RHEL_SERVICES=(nfs-server)
MODULE_VERIFY_BINARIES=(exportfs)
MODULE_NOTES='The installer does not create exports, change firewall rules or explicitly activate the service. Package maintainer scripts can still start it during installation.'
