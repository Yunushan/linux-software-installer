#!/usr/bin/env bash
MODULE_ID='redis'
MODULE_NAME='Redis'
MODULE_DESCRIPTION='In-memory data store from the OS repository'
MODULE_CATEGORY='database'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(redis-server)
MODULE_RHEL_PACKAGES=(redis)
MODULE_DEBIAN_SERVICES=(redis-server)
MODULE_RHEL_SERVICES=(redis)
MODULE_VERIFY_BINARIES=(redis-server redis-cli)
