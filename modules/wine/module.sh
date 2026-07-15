#!/usr/bin/env bash
MODULE_ID='wine'
MODULE_NAME='Wine'
MODULE_DESCRIPTION='Compatibility layer for running Windows applications'
MODULE_CATEGORY='desktop'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(wine)
MODULE_VERIFY_BINARIES=(wine)
MODULE_NOTES='Uses the distribution-supported Wine package; it does not add WineHQ repositories or promise the legacy staging channel.'
