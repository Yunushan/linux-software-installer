#!/usr/bin/env bash
MODULE_ID='bind-utils'
MODULE_NAME='DNS diagnostic tools'
MODULE_DESCRIPTION='dig, nslookup and related DNS clients'
MODULE_CATEGORY='diagnostic'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(bind9-dnsutils)
MODULE_RHEL_PACKAGES=(bind-utils)
MODULE_VERIFY_BINARIES=(dig nslookup)
