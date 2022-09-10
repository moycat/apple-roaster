#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color

apt update
apt install -y apt-transport-https ca-certificates curl gnupg-agent lsb-release software-properties-common

# install docker
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update
apt install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-compose-plugin
