#!/usr/bin/env bash
MODULE_ID='transmission'
MODULE_NAME='Transmission client and daemon'
MODULE_DESCRIPTION='Lightweight BitTorrent client and managed daemon for Debian-family systems'
MODULE_CATEGORY='desktop'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(transmission-gtk transmission-cli transmission-daemon)
MODULE_DEBIAN_SERVICES=(transmission-daemon)
MODULE_VERIFY_BINARIES=(transmission-gtk transmission-daemon)
MODULE_NOTES='Installs the maintained client and daemon from distribution repositories; it does not create torrents, change download directories, expose RPC, or create desktop files.'
