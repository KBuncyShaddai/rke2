#!/bin/bash

sudo systemctl disable apparmor.service
sudo systemctl disable firewalld.service
sudo systemctl disable ufw
sudo systemctl stop apparmor.service
sudo systemctl stop firewalld.service
sudo systemctl stop ufw
sudo systemctl disable swap.target
sudo swapoff -a


sudo sed -i -e "/AllowAgentForwarding/,/VersionAddendum/s/.*AllowTcpForwarding.*/AllowTcpForwarding yes/" /etc/ssh/sshd_config
sudo sed -i -e "/AllowAgentForwarding/,/VersionAddendum/s/.*PermitTunnel.*/PermitTunnel yes/" /etc/ssh/sshd_config

sudo service sshd restart


curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL="v1.24"   sudo -E sh
sudo mkdir -p /etc/rancher/rke2
sudo cp ./config.yaml /etc/rancher/rke2
sudo systemctl enable rke2-server.service
sudo  systemctl start rke2-server.service

sudo cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin

export PATH=$PATH:/opt/rke2/bin:/var/lib/rancher/rke2/bin

export KUBECONFIG=~/.kube/config
sudo cp /etc/rancher/rke2/rke2.yaml /home/dkube/.kube/config
