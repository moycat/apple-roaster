# 🍎 Apple Roaster 🍢

[ 中文 | [English](README-en.md) ]

在 Mac 上自动化部署 Debian！

- ✅ 完全在 Linux 上构建，无需 Mac 设备。
- ✅ 完全在容器中构建，无需启动虚拟机。
- ✅ （几乎）完全自动化部署，仅需一支 U 盘。

已测试设备：

- `mac-mini-2018`：Mac mini (2018)

支持系统：

- `bullseye`：预装常用软件的 Debian 11
- `bullseye-k8s`：预装常用软件与 K8s 的 Debian 11
- `proxmox-ve`：预装常用软件的 Proxmox VE 7

## 使用方式

以默认配置构建 `bullseye` 镜像刷机 U 盘为例。

**构建 USB 镜像**

> 本阶段命令需要由 root 或有 Docker 权限的用户执行。
>
> 会用到特权容器。
> 
> 首次运行会构建两个辅助镜像，耗时可能较长。

首先构建系统镜像。

此步骤会生成系统分区镜像供后续使用，为 gzip 压缩的 RAW 格式。

```shell
$ ./build_image.sh bullseye
...

$ ls -lh output/
total 726M
-rw-r--r-- 1 root root 726M Aug  8 00:00 bullseye-v1.0.0.gz
```

然后构建 USB 镜像。

此步骤会生成可引导的 ISO 镜像，包含安装器与系统镜像。

```shell
$ ./pack_iso.sh -c demo output/bullseye-v1.0.0.gz mac-mini-2018
...

$ ls -lh output/
total 1.5G
-rw-r--r-- 1 root root 726M Aug  8 00:00 bullseye-v1.0.0.gz
-rw-r--r-- 1 root root 738M Aug  8 00:00 bullseye-v1.0.0.mac-mini-2018.demo.iso
```

**烧录 U 盘**

生成的 ISO 镜像现在可以烧录到 U 盘（当然也可以是真的光盘）。

macOS 下可以执行：

```shell
# 找到 U 盘的设备名
diskutil list
# 弹出 U 盘以供烧录
diskutil unmountDisk /dev/diskX
# 烧录！
sudo dd if=output/bullseye-v1.0.0.mac-mini-2018.demo.iso of=/dev/rdiskX bs=4m
```

Linux 下，确保 U 盘的分区没有被挂载，然后执行：

```shell
# 找到 U 盘的块设备
lsblk
# 烧录
sudo dd if=output/bullseye-v1.0.0.mac-mini-2018.demo.iso of=/dev/sdX bs=4m
```

如果 ISO 在远端服务器上，可以在服务器运行 `python3 -m http.server`，将最后一步改为：

```shell
# 烧录 U 盘
curl server:8000/output/bullseye-v1.0.0.mac-mini-2018.demo.iso | sudo dd of=/dev/{rdiskX,sdX} bs=4m
```

### 安装 Debian

虽然本工具希望尽量减少手动步骤，但在每台 Mac 上第一次安装不受官方支持的系统时，需要做如下设置：

1. 开机时按住 `Command-R`，进入恢复模式。
2. 关闭安全启动，允许从外部设备引导，以便 Debian 启动。步骤可以参考[此文档](https://support.apple.com/en-us/HT208198)。

配置完成之后的安装很方便：

1. 插上 U 盘，开机时按住 `Option`，选择 U 盘的启动项。
2. 等待安装完成，随后 Mac 会自动重启进入 Debian。

`bullseye` 的 root 密码是 `toor`。

## 定制

只需在 `images`、`machines`、`cloud-init` 中按格式创建脚本或配置，即可定制安装镜像。

强烈建议在定制前阅读打包、安装脚本的源码，并参考已有实现。

### 系统定制

定制系统需要在 `images` 中创建文件夹，格式如下：

```
├── image.sh # 元数据定义
└── scripts  # 构建脚本
    ├── 00-xxx.sh
    ├── ...
    └── 99-xxx.sh
```

`image.sh` 包含镜像的基本信息，如名称、版本、大小、APT 源等，以便构建脚本和 debootstrap 等使用。

`scripts` 中的脚本会在系统分区的 chroot 环境中按字典序执行，执行软件包安装等定制操作。需要注意的是，因为不是在完整系统中执行，systemd 等将无法调用。

### 机型定制

定制机型需要在 `machines` 中创建文件夹，其中包含脚本文件。

在 USB 引导进入最小 Linux 系统后，会自动执行这些脚本烧录。脚本需要执行分区、写 EFI 引导（ISO 中包含可用的 rEFInd）、植入 cloud-init 配置等操作。

### Cloud-init 定制

定制 cloud-init，需要在 `cloud-init` 中创建文件夹，其中包含 cloud-init 配置文件。

cloud-init 在制作 ISO 时可选的，可以用于系统初次启动时的初始化。文件夹会被原样放置在本地数据源中.

## FAQ

### 使用代理

可以在脚本参数中加入 `-p <proxy>` 以在构建环境中使用代理服务器，如 `-p http://127.0.0.1:7890`。

值会被传递为 `http_proxy` 与 `https_proxy`。

### 更换 APT 源

更换系统镜像的 APT 源，需要修改 `images` 目录下镜像文件夹的 `image.sh`。

更换辅助镜像的 APT 源，需要修改 `tools` 中的 Dockerfile。

## TODO

- [ ] 兼容性测试与提升。
- [ ] 支持更多机型。
- [ ] 支持 M1 芯片。
