#!/usr/bin/env bash
MODULE_ID='postgresql'
MODULE_NAME='PostgreSQL Server'
MODULE_DESCRIPTION='PostgreSQL database server and contributed extensions'
MODULE_CATEGORY='database'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(postgresql postgresql-contrib)
MODULE_RHEL_PACKAGES=(postgresql-server postgresql-contrib)
MODULE_TARGET_PACKAGE_OVERRIDES=(ubuntu:26.04:x86_64=postgresql)
MODULE_DEBIAN_SERVICES=(postgresql)
MODULE_RHEL_SERVICES=(postgresql)
MODULE_VERIFY_BINARIES=(psql)
MODULE_NOTES='RHEL-family database initialization is intentionally left to the administrator.'
