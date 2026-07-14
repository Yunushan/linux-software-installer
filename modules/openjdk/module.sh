#!/usr/bin/env bash
MODULE_ID='openjdk'
MODULE_NAME='OpenJDK development kit'
MODULE_DESCRIPTION='Supported Java development kit from the OS repository'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(default-jdk)
MODULE_RHEL_PACKAGES=(java-17-openjdk-devel)
MODULE_VERIFY_BINARIES=(java javac)
