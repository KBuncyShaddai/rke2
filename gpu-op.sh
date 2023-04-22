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

echo "\t Copied nvidia runtime config to containerd config\n"
echo  "\tHelm installing nvidia gpu operator\n"
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia && helm repo update
helm install gpu-operator --wait  -n gpu-operator --create-namespace    nvidia/gpu-operator --set toolkit.env[0].name=CONTAINERD_CONFIG     --set toolkit.env[0].value=/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl     --set toolkit.env[1].name=CONTAINERD_SOCKET     --set toolkit.env[1].value=/run/k3s/containerd/containerd.sock     --set toolkit.env[2].name=CONTAINERD_RUNTIME_CLASS     --set toolkit.env[2].value=nvidia     --set toolkit.env[3].name=CONTAINERD_SET_AS_DEFAULT     --set-string toolkit.env[3].value=true 
