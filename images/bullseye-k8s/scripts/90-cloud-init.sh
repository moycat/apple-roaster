#!/bin/bash
set -ex

export CLOUD_INIT_VERSION=21.2
export SIX_VERSION=1.16.0

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color

apt update
apt install -y cloud-guest-utils python3 python3-pip

# install six
wget -O - https://github.com/benjaminp/six/archive/refs/tags/${SIX_VERSION}.tar.gz | tar xzf - -C /tmp
cd "/tmp/six-${SIX_VERSION}"
python3 setup.py install

# install cloud-init
wget -O - https://github.com/canonical/cloud-init/releases/download/${CLOUD_INIT_VERSION}/cloud-init-${CLOUD_INIT_VERSION}.tar.gz | tar xzf - -C /tmp
cd "/tmp/cloud-init-${CLOUD_INIT_VERSION}"
pip3 install -r requirements.txt
python3 setup.py build
python3 setup.py install --init-system systemd
mv /usr/local/bin/cloud-{id,init,init-per} /usr/bin/
systemctl enable cloud-init-local.service cloud-init.service cloud-config.service cloud-final.service

# apply cloud config
cat >/etc/cloud/cloud.cfg <<EOF
disable_root: false
preserve_hostname: false

# The modules that run in the 'init' stage
cloud_init_modules:
 - seed_random
 - bootcmd
 - write-files
 - disk_setup
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
# Emit the cloud config ready event
# this can be used by upstart jobs for 'start on cloud-config'.
 - set-passwords
 - resolv_conf
 - mounts

unverified_modules: ['resolv_conf']

# The modules that run in the 'final' stage
cloud_final_modules:
 - runcmd
 - scripts-vendor
 - scripts-user
 - ssh-authkey-fingerprints
 - power-state-change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
   # This will affect which distro class gets used
   distro: debian
EOF
