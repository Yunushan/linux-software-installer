#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=${1:-/workspace}

"$ROOT_DIR/install.sh" doctor
"$ROOT_DIR/install.sh" list > /dev/null
"$ROOT_DIR/install.sh" plan --no-refresh base-tools git > /tmp/linux-software-installer-plan.txt
grep -Eq '(apt-get|dnf) install' /tmp/linux-software-installer-plan.txt
grep -q 'no system changes were made' /tmp/linux-software-installer-plan.txt
