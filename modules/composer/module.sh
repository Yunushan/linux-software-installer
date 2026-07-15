#!/usr/bin/env bash
MODULE_ID='composer'
MODULE_NAME='Composer'
MODULE_DESCRIPTION='Dependency manager for PHP projects'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(composer)
MODULE_VERIFY_BINARIES=(composer)
MODULE_NOTES='Uses the distribution package; no remote installer is downloaded.'
