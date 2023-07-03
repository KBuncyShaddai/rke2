#!/bin/bash

# Variables

node_type=${1-:"server"}  # "server" / "agent"
kubernetes_version="v1.24"


# -----------------------
#    Network Setup
#------------------------

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


#--------------------
#  RKE Setup
#--------------------

curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=$kubernetes_version  INSTALL_RKE2_TYPE=$node_type	 sudo -E sh
sudo systemctl enable rke2-$node_type.service
sudo mkdir -p /etc/rancher/rke2
# Config will be applied from /etc/rancher/rke2/config.yaml
sudo  systemctl start rke2-$node_type.service


#--------------------
#  Kubeconfig
#--------------------

if [[ "$node_type" == "server" ]] 
then
	sudo cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin
	export PATH=$PATH:/opt/rke2/bin:/var/lib/rancher/rke2/bin
	sudo cp /etc/rancher/rke2/rke2.yaml /home/dkube/.kube/config
	export KUBECONFIG=~/.kube/config
fi

################################################
# authored by buncy.shaddai@oneconvergence.com #
################################################
