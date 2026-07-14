#!/usr/bin/env bash
MODULE_ID='sqlite'
MODULE_NAME='SQLite'
MODULE_DESCRIPTION='Embedded SQL database and command-line shell'
MODULE_CATEGORY='database'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(sqlite3)
MODULE_RHEL_PACKAGES=(sqlite)
MODULE_VERIFY_BINARIES=(sqlite3)
