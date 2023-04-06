#!/bin/bash



MASTER_SSH_KEY=/home/ubuntu/keys/104/jenkins-rke.pem
MASTER_SSH_USER=dkube
MASTER_NODE=$RKE2_HOST
CONFIG_FILE=./config.yaml

AGENT_NODES=()
AGENT_SSH_KEYS=()
AGENT_SSH_USER=()
AGENT_NODE_TYPE=()

function white_printf  { printf "\t\033[1;37m$@\033[0m";  }
function red_printf    { printf "\t\033[31m$@\033[0m";    }                                                               #
function green_printf  { printf "\t\033[32m$@\033[0m";    }                                                               #
function yellow_printf { printf "\t\033[33m$@\033[0m";    }

function setAgentConfig {
  white_printf	"Fetching token from Server node $NODE.\n"
  token=$(ssh -i $SSH_KEY $SSH_USER@$NODE sudo cat /var/lib/rancher/rke2/server/node-token)
  green_printf "Token fetched.\n"
  cat config.yaml > agent-config.yaml
  echo server: https://$NODE:9345 >> agent-config.yaml
  echo token: $token >> agent-config.yaml
  green_printf "Configured agent-config.yaml.\n"
}

function setServerConfig {
  cat config.yaml > server-config.yaml
  echo node-ip: $NODE >> server-config.yaml
  greeb_printf "Configured server-config.yaml"
}

function copyConfig {
  scp -i $SSH_KEY $CONFIG_FILE  $SSH_USER@$NODE:/tmp/config.yaml
  ssh -i $SSH_KEY $SSH_USER@$NODE sudo mkdir -p /etc/rancher/rke2
  ssh -i $SSH_KEY $SSH_USER@$NODE sudo cp /tmp/config.yaml /etc/rancher/rke2/config.yaml
  green_printf "Copied config to $NODE_TYPE node $NODE.\n"
}

function installRKE2 {
	ssh -i $SSH_KEY $SSH_USER@$NODE 'bash -s' < install.sh $NODE_TYPE
}

function setupMasterNode {
  SSH_USER=$MASTER_SSH_USER
  SSH_KEY=$MASTER_SSH_KEY
  NODE=$MASTER_NODE
  NODE_TYPE=server

  setServerConfig
  CONFIG_FILE=server-config.yaml
  copyConfig
  installRKE2
}

setupMasterNode
