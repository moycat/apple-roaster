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

# install kernel
apt update
apt install -y linux-base initramfs-tools linux-image-amd64

# write refind presets
cat >/boot/refind-linux.conf <<EOF
"default" "quiet ro root=__ROOT_DEVICE__ noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
"rescue mode" "quiet ro root=__ROOT_DEVICE__ systemd.unit=rescue.target"
EOF

# write kernel parameters
cat >/etc/sysctl.d/00-default.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
EOF
