#!/usr/bin/env bash
MODULE_ID='tor-browser'
MODULE_NAME='Tor Browser Launcher'
MODULE_DESCRIPTION='Tor Browser launcher from Ubuntu repositories'
MODULE_CATEGORY='desktop'
MODULE_STATUS='stable'
MODULE_RISK='low'
MODULE_NOTES='The launcher downloads Tor Browser on first use.'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(torbrowser-launcher)
MODULE_VERIFY_BINARIES=(torbrowser-launcher)
MODULE_TARGET_CELLS=(ubuntu:24.04:x86_64)
