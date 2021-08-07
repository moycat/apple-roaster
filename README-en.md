# 🍎 Apple Roaster 🍢

[ [中文](README.md) | English ]

Deploy Debian on Mac, in an automated manner!

- ✅ Building on Linux without Mac required.
- ✅ Building in containers without VM involved.
- ✅ (Almost) fully automated deployment with a USB stick.

Tested devices:

- Mac mini (2018)

OS variants:

- Debian 11 “Bullseye”

## Usage

Following is an example of building and burning a `bullseye` USB installer with default configuration.

**Build the USB image**

> The commands shall be executed by root, or a user with Docker permission.
>
> Privileged containers are used.
> 
> Two helper images are built on first run, which can be slow.

First build the system image.

A gzip compressed raw image containing system partition is generated for subsequent use.

```shell
$ ./build_image.sh bullseye
...

$ ls -lh output/
total 726M
-rw-r--r-- 1 root root 726M Aug  8 00:00 bullseye-v1.0.0.gz
```

Then build the USB image.

A bootable ISO image with the installer and system image is generated.

In this example, we use `demo` cloud-init configuration and `mac-mini-2018` machine script.

```shell
$ ./pack_iso.sh -c demo output/bullseye-v1.0.0.gz mac-mini-2018
...

$ ls -lh output/
total 1.5G
-rw-r--r-- 1 root root 726M Aug  8 00:00 bullseye-v1.0.0.gz
-rw-r--r-- 1 root root 738M Aug  8 00:00 bullseye-v1.0.0.iso
```

**Burn the USB stick**

Now the ISO file can be burnt to a USB drive (or some real optical media, of course).

For macOS, do as follows:

```shell
# find the name of the usb stick
diskutil list
# unmount it for writing
diskutil unmountDisk /dev/diskX
# burn!
sudo dd if=output/bullseye-v1.0.0.iso of=/dev/rdiskX bs=4m
```

For Linux, make sure the existing partitions aren't mounted, and run:

```shell
# find the block device of the usb stick
lsblk
# burn!
sudo dd if=output/bullseye-v1.0.0.iso of=/dev/sdX bs=4m
```

If the ISO is generated remotely, just run `python3 -m http.server` on server, and change the last step to:

```shell
# burn!
curl server:8000/output/bullseye-v1.0.0.iso | sudo dd of=/dev/{rdiskX,sdX} bs=4m
```

### Install Debian

Though this tool is meant to be as automated as possible, you do need to configure the Mac at the first time you install a funny OS on it.

1. Press `Command-R` at boot, and enter recovery mode.
2. Turn off secure boot and allow external boot as described [here](https://support.apple.com/en-us/HT208198), so that Debian can boot.

Once it's configured, the installation is simple:

1. Insert the stick, press `Option` at boot, and select the boot option from USB.
2. Wait for completion, after which Mac will automatically reboot into Debian.

## Customization

You can customize the image by creating scripts or configurations in `images`, `machines` and `cloud-init`.

It's strongly recommended to read the packing and installation scripts before customization, and refer to existing ones.

### System customization

To customize the image, create a directory in `image` of this layout:

```
├── image.sh # metadata
└── scripts  # build scripts
    ├── 00-xxx.sh
    ├── ...
    └── 99-xxx.sh
```

`image.sh` contains the basic configuration like name, version, size, apt mirror, etc. for the build script and debootstrap.

`scripts` contains the scripts that are executed in lexicographic order in chroot environment of the system partition. Note that there isn't a full system, so systemd and some others are unavailable.

### Model customization

To customize the model, create a directory in `machines` with one or more scripts in it.

These scripts are executed after the Mac boots into the minimal Linux from the USB stick. The scripts shall create partitions, write EFI files (the ISO has rEFInd inside), plant cloud-init configurations, etc.

### Cloud-init customization

To customize cloud-init, create a directory in `cloud-init` with cloud-init config files.

Cloud-init is optional when creating ISO. It's used for system initialization on first boot. The directory is copied as a local datasource.

## TODO

- [ ] Compatibility test & improvement.
- [ ] Support for more models.
- [ ] Support for the M1 chip.
