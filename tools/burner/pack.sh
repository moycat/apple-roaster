#!/bin/bash -e

SCRIPTS="${PACK_SCRIPTS}"
CLOUD_INIT="${PACK_CLOUD_INIT}"
OUTPUT="${PACK_OUTPUT}"

if [[ -z "${OUTPUT}" ]]; then
  echo "PACK_OUTPUT must not be empty!"
  exit 1
elif [[ -e "${OUTPUT}" ]]; then
  echo "PACK_OUTPUT already exists!"
  exit 1
fi
if [[ ! -d "${SCRIPTS}" ]]; then
  echo "PACK_SCRIPTS doesn't exist!"
fi

cd /opt/mll

# copy tools
mkdir -p work/overlay_rootfs/sbin work/overlay_rootfs/opt
cp /opt/mkfs.fat /opt/fdisk work/overlay_rootfs/sbin/
cp -r /opt/refind work/overlay_rootfs/opt/refind

# copy scripts
mkdir -p work/overlay_rootfs/etc/autorun
cp -r "${PACK_SCRIPTS}"/* -p work/overlay_rootfs/etc/autorun
if [ -d "${CLOUD_INIT}" ]; then
  cp -r "${CLOUD_INIT}" work/overlay_rootfs/opt/cloud-init
fi

# generate iso
./09_generate_rootfs.sh
./10_pack_rootfs.sh
./11_generate_overlay.sh
./13_prepare_iso.sh
./14_generate_iso.sh

cp minimal_linux_live.iso "${OUTPUT}"
