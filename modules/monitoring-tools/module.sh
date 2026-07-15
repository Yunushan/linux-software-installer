#!/usr/bin/env bash
MODULE_ID='monitoring-tools'
MODULE_NAME='Monitoring tools'
MODULE_DESCRIPTION='Curated host and process monitoring command bundle'
MODULE_CATEGORY='diagnostics'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(htop iftop atop glances monit powertop iotop apachetop)
MODULE_VERIFY_BINARIES=(htop iftop atop glances monit powertop iotop apachetop)
MODULE_NOTES='Installs monitoring commands only; it does not configure Monit checks or enable services.'
