#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color

# set apt sources
cat >/etc/apt/sources.list <<EOF
deb ${APT_MIRROR} bullseye main contrib non-free
deb ${APT_MIRROR}-security bullseye-security main contrib non-free
EOF

# install wget
apt update
apt install -y wget

# add pve source
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
