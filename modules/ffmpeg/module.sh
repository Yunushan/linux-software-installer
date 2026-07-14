#!/usr/bin/env bash
MODULE_ID='ffmpeg'
MODULE_NAME='FFmpeg'
MODULE_DESCRIPTION='Audio and video processing toolkit'
MODULE_CATEGORY='media'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(ffmpeg)
MODULE_VERIFY_BINARIES=(ffmpeg ffprobe)
MODULE_NOTES='RHEL-family support would require an additional repository and is intentionally excluded.'
