#!/bin/bash
set -ex

# set apt sources
cat >/etc/apt/sources.list <<EOF
deb ${APT_MIRROR} bullseye main contrib non-free
deb ${APT_MIRROR} bullseye-updates main contrib non-free
deb ${APT_MIRROR} bullseye-backports main contrib non-free
deb ${APT_MIRROR}-security bullseye-security main contrib non-free
EOF

# upgrade existing packages
export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color
apt update
apt upgrade -y
