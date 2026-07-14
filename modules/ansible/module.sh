#!/usr/bin/env bash
MODULE_ID='ansible'
MODULE_NAME='Ansible Core'
MODULE_DESCRIPTION='Agentless configuration-management engine'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(ansible-core)
MODULE_RHEL_PACKAGES=(ansible-core)
MODULE_VERIFY_BINARIES=(ansible ansible-playbook)
MODULE_NOTES='Installs the version supplied by the active OS repositories.'
