#!/usr/bin/env bash
MODULE_ID='python'
MODULE_NAME='Python 3 toolchain'
MODULE_DESCRIPTION='Python 3 interpreter, pip and virtual-environment support'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(python3 python3-pip python3-venv)
MODULE_RHEL_PACKAGES=(python3 python3-pip)
MODULE_VERIFY_BINARIES=(python3 pip3)
