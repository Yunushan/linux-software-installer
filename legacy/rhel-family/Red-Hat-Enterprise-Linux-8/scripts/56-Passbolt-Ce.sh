#!/bin/bash

#56-Passbolt-CE
sudo dnf -vy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo wget -O /root/Downloads/passbolt-repo-setup.ce.sh \
https://raw.githubusercontent.com/passbolt/passbolt-dep-scripts/main/passbolt-repo-setup.ce.sh
[ "$(sha256sum /root/Downloads/passbolt-repo-setup.ce.sh | awk '{print $1}')" = \
"ce96ab921e2fa448d48da018e3be0e9646791629dffb13707bbc49b55c739490" ] && sudo bash /root/Downloads/passbolt-repo-setup.ce.sh \
|| echo "Bad checksum. Aborting" && rm -f /root/Downloads/passbolt-repo-setup.ce.sh
sudo dnf -vy install passbolt-ce-server
sudo /usr/local/bin/passbolt-configure