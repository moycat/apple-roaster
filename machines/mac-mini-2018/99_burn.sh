#!/bin/sh -e

DEVICE="/dev/nvme0n1"
SYS_IMAGE="/sys.gz"
CLOUD_INIT_DIR="/opt/cloud-init"

if [ ! -b "${DEVICE}" ]; then
  echo "${DEVICE} is not a block device!"
  exit 1
fi
if [ ! -f "${SYS_IMAGE}" ]; then
  echo "${SYS_IMAGE} does not exist!"
  exit 1
fi

function abort() {
  echo "aborted"
  exit 1
}

trap abort INT

echo "burning will be started in 3 seconds"
sleep 3

# create partitions
echo -e "g\nn\n1\n\n+512M\nn\n2\n\n\nt\n1\n1\nw\n" | fdisk -w always -W always "${DEVICE}"
mkfs.fat -F32 -s1 "${DEVICE}p1"

# burn image
zcat "${SYS_IMAGE}" | dd "of=${DEVICE}p2" bs=4M

# mount
mkdir -p /mnt
mount "${DEVICE}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${DEVICE}p1" /mnt/boot/efi

# deploy boot config
cp -r /opt/refind /mnt/boot/efi/EFI
cat >/mnt/etc/fstab <<EOF
${DEVICE}p2 / ext4 errors=remount-ro 0 1
${DEVICE}p1 /boot/efi vfat umask=0077 0 1
EOF
if [ -f "/mnt/boot/refind-linux.conf" ]; then sed -i "s/__ROOT_DEVICE__/${DEVICE//\//\\\/}p2/g" /mnt/boot/refind-linux.conf; fi

# deploy cloud-init
rm -rf /mnt/var/lib/cloud/seed/nocloud
if [ -d "/opt/cloud-init" ]; then
  mkdir -p /mnt/var/lib/cloud/seed
  cp -r "${CLOUD_INIT_DIR}" /mnt/var/lib/cloud/seed/nocloud
  chmod -R g-rwx,o-rwx /mnt/var/lib/cloud/seed/nocloud
fi

echo "successfully burnt, rebooting..."
sleep 3
reboot
