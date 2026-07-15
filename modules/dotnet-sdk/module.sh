#!/usr/bin/env bash
MODULE_ID='dotnet-sdk'
MODULE_NAME='.NET SDK 10'
MODULE_DESCRIPTION='.NET 10 software development kit from RHEL-family repositories'
MODULE_CATEGORY='development'
MODULE_FAMILIES=(rhel)
MODULE_RHEL_PACKAGES=(dotnet-sdk-10.0)
MODULE_VERIFY_BINARIES=(dotnet)
MODULE_NOTES='Uses the distribution AppStream package and does not run a remote installer script.'
