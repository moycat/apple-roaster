#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color

apt update

# standard packages
apt install -y $(tasksel --task-packages standard)
apt install -y $(tasksel --task-packages ssh-server)

# common packages
apt install -y build-essential \
    python \
    python3 \
    python3-pip \
    gcc \
    g++ \
    git \
    make \
    cmake \
    apt-transport-https \
    ca-certificates \
    curl \
    fio \
    gnupg \
    gnupg2 \
    less \
    lsof \
    openssh-client \
    rsync \
    socat \
    sudo \
    tcpdump \
    tzdata \
    unzip \
    vim \
    wget \
    zip

# apply misc settings
echo "Etc/UTC" > /etc/timezone
rm /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
update-alternatives --set editor /usr/bin/vim.basic
update-rc.d -f ntp remove
echo -e "toor\ntoor" | passwd root
