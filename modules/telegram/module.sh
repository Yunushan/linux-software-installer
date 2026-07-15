#!/usr/bin/env bash
MODULE_ID='telegram'
MODULE_NAME='Telegram Desktop'
MODULE_DESCRIPTION='Telegram desktop client from Debian repositories'
MODULE_CATEGORY='desktop'
MODULE_STATUS='stable'
MODULE_RISK='low'
MODULE_NOTES='Uses the distribution-maintained package without adding a third-party repository.'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(telegram-desktop)
MODULE_VERIFY_BINARIES=(telegram-desktop)
MODULE_TARGET_CELLS=(debian:12:x86_64)
