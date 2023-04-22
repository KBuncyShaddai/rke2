#!/bin/bash

if grep -q 'data-dir' /etc/rancher/rke2/config.yaml; then
  DATA_DIR=$(grep 'data-dir' /etc/rancher/rke2/config.yaml | awk '{print $2}')
else
  DATA_DIR=/var/lib/rancher/rke2
fi
CONTAINERD_CONFIG=$DATA_DIR/agent/etc/containerd/config.toml.tmpl
cat <<EOF | sudo tee $CONTAINERD_CONFIG
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    enable_selinux = false
    sandbox_image = "index.docker.io/rancher/pause:3.2"
    stream_server_address = "127.0.0.1"
    stream_server_port = "10010"
    [plugins."io.containerd.grpc.v1.cri".containerd]
      disable_snapshot_annotations = true
      snapshotter = "overlayfs"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
  [plugins."io.containerd.internal.v1.opt"]
    path = "/data/rancher/rke2/agent/containerd"
EOF
CONTAINERD_SOCKET=/run/k3s/containerd/containerd.sock

echo "\t Copied nvidia runtime config to containerd config $CONTAINERD_CONFIG\n"
