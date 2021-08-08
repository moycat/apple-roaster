#!/bin/bash
set -ex

K8S_VERSION=1.22.0

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-color

# install k8s
apt-get update
apt-get install -y apt-transport-https curl gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y "kubelet=${K8S_VERSION}-00" "kubeadm=${K8S_VERSION}-00" "kubectl=${K8S_VERSION}-00"
apt-mark hold kubelet kubeadm kubectl

# start docker (twisted but working)
/usr/bin/containerd &
CONTAINERD_PID=$!
while ! test -S /run/containerd/containerd.sock; do sleep 1; done
/usr/bin/dockerd -H unix:// --containerd=/run/containerd/containerd.sock &
DOCKERD_PID=$!
while ! docker info 2>&1 >/dev/null; do sleep 1; done

# preload k8s
kubeadm config images pull

# stop docker
kill ${CONTAINERD_PID} ${DOCKERD_PID}
wait ${CONTAINERD_PID}
wait ${DOCKERD_PID}
