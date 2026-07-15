#!/usr/bin/env bash
MODULE_ID='qt'
MODULE_NAME='Qt Creator and Qt development tools'
MODULE_DESCRIPTION='Qt Creator IDE with Qt 6 base headers and build tools'
MODULE_CATEGORY='development'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(qtcreator qt6-base-dev)
MODULE_VERIFY_BINARIES=(qtcreator qmake6)
MODULE_NOTES='Installs the supported distribution Qt 6 toolchain rather than the legacy online installer.'
