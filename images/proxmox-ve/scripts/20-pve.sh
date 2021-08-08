#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color

# block useless modules
cat >/etc/modprobe.d/blocklist.conf <<EOF
blacklist nouveau
blacklist b43
blacklist bcma
blacklist i915
EOF

# prepare
apt update
apt full-upgrade -y
touch /proxmox_install_mode # so that ifupdown2 can be normally installed
chmod +x /proxmox_install_mode

# install pve environment
apt install -y proxmox-ve postfix open-iscsi

# clean up
rm -rf /proxmox_install_mode
rm /etc/apt/sources.list.d/pve-enterprise.list

# mask services to prevent boot delay
systemctl mask systemd-udev-settle
systemctl mask ifupdown2-pre

# write refind presets
cat >/boot/refind-linux.conf <<EOF
"default" "quiet ro root=__ROOT_DEVICE__ noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
"rescue mode" "quiet ro root=__ROOT_DEVICE__ systemd.unit=rescue.target"
EOF

# enable nested virtualization
echo "options kvm-intel nested=Y" > /etc/modprobe.d/kvm-intel.conf

# write kernel parameters
cat >/etc/sysctl.d/00-default.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
EOF
