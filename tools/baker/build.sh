#!/bin/bash -e

# get settings from env variables
SCRIPTS="${BUILD_SCRIPTS}"
OUTPUT="${BUILD_OUTPUT}"
IMAGE_SIZE="${BUILD_IMAGE_SIZE}"
OS_DISTRO="${BUILD_OS_DISTRO}"
OS_VERSION="${BUILD_OS_VERSION}"
PROXY="${BUILD_PROXY}"
APT_MIRROR="${BUILD_APT_MIRROR}"

function die() {
  echo "$1"
  exit 1
}

# check parameters
if [[ ! -d "${SCRIPTS}" ]]; then
  die "BUILD_SCRIPTS must be a directory!"
fi
if [[ -z "${OUTPUT}" ]]; then
  die "BUILD_OUTPUT mustn't be empty!"
elif [[ -e "${OUTPUT}" ]]; then
  die "BUILD_OUTPUT already exists!"
fi
if [[ ! "${IMAGE_SIZE}" =~ ^[1-9][0-9]*$ ]]; then
  die "IMAGE_SIZE is invalid!"
fi
if [[ -z "${OS_DISTRO}" ]]; then
  die "OS_DISTRO mustn't be empty!"
fi
if [[ -z "${OS_VERSION}" ]]; then
  die "OS_VERSION mustn't be empty!"
fi

WORKSPACE="$(mktemp -d)"
SYS_IMAGE="${WORKSPACE}/sys.raw"
mkdir -p "${WORKSPACE}/mnt"
mkdir -p "$(dirname "${OUTPUT}")"

function cleanup() {
  umount "${WORKSPACE}/mnt/sys/fs/cgroup/devices" >/dev/null 2>&1 || true
  umount "${WORKSPACE}/mnt/sys/fs/cgroup" >/dev/null 2>&1 || true
  umount "${WORKSPACE}/mnt/dev/pts" >/dev/null 2>&1 || true
  umount "${WORKSPACE}/mnt/dev" >/dev/null 2>&1 || true
  umount "${WORKSPACE}/mnt/proc" >/dev/null 2>&1 || true
  umount "${WORKSPACE}/mnt/sys" >/dev/null 2>&1 || true
  umount "${WORKSPACE}/mnt" >/dev/null 2>&1 || true
  losetup -d "${SYS_DEVICE}" >/dev/null 2>&1 || true
}

function mount_dev() {
  mount -o bind /dev "${WORKSPACE}/mnt/dev"
  mount -o bind /dev/pts "${WORKSPACE}/mnt/dev/pts"
  mount -t proc none "${WORKSPACE}/mnt/proc"
  mount -t sysfs none "${WORKSPACE}/mnt/sys"
  mount --bind /sys/fs/cgroup "${WORKSPACE}/mnt/sys/fs/cgroup"
  mount --bind /sys/fs/cgroup/devices "${WORKSPACE}/mnt/sys/fs/cgroup/devices"
  chmod 666 "${WORKSPACE}/mnt/dev/null"
  chmod 666 "${WORKSPACE}/mnt/dev/zero"
}

function umount_dev() {
  umount "${WORKSPACE}/mnt/sys/fs/cgroup/devices"
  umount "${WORKSPACE}/mnt/sys/fs/cgroup"
  umount "${WORKSPACE}/mnt/dev/pts"
  umount "${WORKSPACE}/mnt/dev"
  umount "${WORKSPACE}/mnt/proc"
  umount "${WORKSPACE}/mnt/sys"
}

function build_image() {
  # create & mount image
  dd if=/dev/zero "of=${SYS_IMAGE}" conv=sparse bs=1M "count=${IMAGE_SIZE}"
  SYS_DEVICE="$(losetup -f --show "${SYS_IMAGE}")"
  trap cleanup EXIT
  mkfs.ext4 "${SYS_DEVICE}"
  # mount partition & debootstrap
  mount "${SYS_DEVICE}" "${WORKSPACE}/mnt"
  debootstrap "${OS_VERSION}" "${WORKSPACE}/mnt" "${APT_MIRROR}"
  # execute scripts
  mount_dev
  export APT_MIRROR http_proxy https_proxy
  for script in "${SCRIPTS}"/*; do
    chroot "${WORKSPACE}/mnt" bash -c "$(cat "${script}")"
  done
  # clean up
  umount_dev
  fstrim -v "${WORKSPACE}/mnt"
  umount "${WORKSPACE}/mnt"
  e2fsck -f -p "${SYS_DEVICE}"
  losetup -d "${SYS_DEVICE}"
  # output image
  gzip --fast -c "${SYS_IMAGE}" >"${OUTPUT}"
}

build_image
