#!/bin/bash
set -ex

apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/* /var/log/apt/* /var/log/dpkg.log
rm -rf /root/.cache
rm -rf /tmp/* /var/tmp/*
