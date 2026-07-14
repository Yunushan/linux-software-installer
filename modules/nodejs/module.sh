#!/usr/bin/env bash
MODULE_ID='nodejs'
MODULE_NAME='Node.js and npm'
MODULE_DESCRIPTION='JavaScript runtime and package client from the OS repository'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(nodejs npm)
MODULE_RHEL_PACKAGES=(nodejs npm)
MODULE_VERIFY_BINARIES=(node npm)
MODULE_NOTES='Installs the distribution-provided release; no curl-to-shell installer is used.'
