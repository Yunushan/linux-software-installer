#!/usr/bin/env bash
MODULE_ID='tinc'
MODULE_NAME='tinc'
MODULE_DESCRIPTION='Mesh VPN daemon and client tools'
MODULE_CATEGORY='network'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(tinc)
MODULE_VERIFY_BINARIES=(tincd)
MODULE_NOTES='Installs the package only; VPN keys, peers and services remain administrator-managed.'
