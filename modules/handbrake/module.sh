#!/usr/bin/env bash
MODULE_ID='handbrake'
MODULE_NAME='HandBrake'
MODULE_DESCRIPTION='Video transcoder with graphical and command-line clients'
MODULE_CATEGORY='media'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(handbrake handbrake-cli)
MODULE_VERIFY_BINARIES=(ghb HandBrakeCLI)
