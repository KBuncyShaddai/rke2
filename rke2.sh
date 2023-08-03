#!/bin/bash

KUBERNETES_VERSION=v1.24

MASTER_SSH_KEY=
MASTER_SSH_USER=
MASTER_NODE=
CONFIG_FILE=./config.yaml

#MASTER_SSH_KEY=/home/ubuntu/keys/104/jenkins-rke.pem
#MASTER_SSH_USER=dkube
#MASTER_NODE=192.168.200.104
#CONFIG_FILE=./config.yaml

AGENT_NODES=()
AGENT_SSH_KEYS=()
AGENT_SSH_USERS=()
AGENT_NODE_TYPE=()


#AGENT_NODES=(192.168.200.107 192.168.200.134 192.168.200.122)
#AGENT_SSH_KEYS=(/home/ubuntu/keys/107/jenkins-rke.pem /home/ubuntu/keys/134/jenkins-rke.pem /home/ubuntu/keys/122/jenkins-rke.pem)
#AGENT_SSH_USERS=(dkube dkube dkube)
#AGENT_NODE_TYPE=(agent agent agent)

function white_printf  { printf "\t\033[1;37m$@\033[0m";  }
function red_printf    { printf "\t\033[31m$@\033[0m";    }                                                               #
function green_printf  { printf "\t\033[32m$@\033[0m";    }                                                               #
function yellow_printf { printf "\t\033[33m$@\033[0m";    }

function setAgentConfig {
  SSH_USER=$MASTER_SSH_USER
  SSH_KEY=$MASTER_SSH_KEY
  NODE=$MASTER_NODE
  
  yellow_printf	"Fetching token from Server node $NODE.\n"
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
  green_printf "Configured server-config.yaml"
}

function copyConfig {
  yellow_printf "Copying config to $NODE......\n" 
  scp -i $SSH_KEY $CONFIG_FILE  $SSH_USER@$NODE:/tmp/config.yaml
  ssh -i $SSH_KEY $SSH_USER@$NODE sudo mkdir -p /etc/rancher/rke2
  ssh -i $SSH_KEY $SSH_USER@$NODE sudo cp /tmp/config.yaml /etc/rancher/rke2/config.yaml
  green_printf "Copied config to $NODE_TYPE node $NODE.\n"
}

function installRKE2 {
  copyConfig
  yellow_printf "Starting rke2 service on $NODE......\n"
  ssh -i $SSH_KEY $SSH_USER@$NODE 'sudo bash -s' < install.sh $NODE_TYPE
  green_printf "Setup RKE2 on $NODE successfully\n"
  getNodes
}

function setupMasterNode {
  SSH_USER=$MASTER_SSH_USER
  SSH_KEY=$MASTER_SSH_KEY
  NODE=$MASTER_NODE
  NODE_TYPE=server

  setServerConfig
  CONFIG_FILE=server-config.yaml
  installRKE2
}
function getNodes {
 ssh -i $MASTER_SSH_KEY  $MASTER_SSH_USER@$MASTER_NODE kubectl get nodes
}

function setupAgentNodes {
  agent_nodes=${#AGENT_NODES[@]}
  white_printf "Total Agent Nodes    : $agent_nodes.\n\n"
  if [ $agent_nodes != 0 ]
  then
    setAgentConfig
    CONFIG_FILE=agent-config.yaml
    yellow_printf "Setting up Agent Nodes\n"
    c=0
    while [ $c -lt $agent_nodes ]
    do
      SSH_USER=${AGENT_SSH_USERS[$c]}
      SSH_KEY=${AGENT_SSH_KEYS[$c]}
      NODE=${AGENT_NODES[$c]}
      NODE_TYPE=${AGENT_NODE_TYPE[$c]}
      installRKE2
      c=`expr $c + 1`
    done
  fi
}

function uninstallRKE2 {
  ssh -i $SSH_KEY $SSH_USER@$NODE 'sudo bash -s' < uninstall.sh   # 2> /dev/null
#  yellow_printf "\tUninstalling Cluster from $NODE....\n" ; sudo /usr/local/bin/rke2-killall.sh ; sudo /usr/local/bin/rke2-uninstall.sh; } || red_printf "No cluster setup on $NODE to Uninstall\n" ; ]
  if [ $? -eq 0 ]
  then
    green_printf "Uninstalled RKE2 on $NODE successfully.\n"
  else
    red_printf "No RKE2 cluster setup on $NODE to Uninstall.\n"
  fi
}

function uninstallCluster {
 
  agent_nodes=${#AGENT_NODES[@]}
  if [ $agent_nodes != 0 ]
  then
    c=0
    while [ $c -lt $agent_nodes ]
    do
      SSH_USER=${AGENT_SSH_USERS[$c]}
      SSH_KEY=${AGENT_SSH_KEYS[$c]}
      NODE=${AGENT_NODES[$c]}
      NODE_TYPE=${AGENT_NODE_TYPE[$c]}
      uninstallRKE2
      c=`expr $c + 1`
    done
  fi
  SSH_USER=$MASTER_SSH_USER
  SSH_KEY=$MASTER_SSH_KEY
  NODE=$MASTER_NODE
  NODE_TYPE=server

  uninstallRKE2
}

function updateK8sVersion {
  sed -i 's/kubernetes_version=.*/kubernetes_version=$KUBERNETES_VERSION/g' install.sh
}
function drke2 {
  if [ $# -eq 0 ]
  then 
    echo "##========================================##"
    white_printf "Fill the Master and Agent Node details.\n"
    white_printf "Usage : drke2 up or drke2 down\n"
    echo "##========================================##"
  fi
  if [ "$1" == "up" ]
  then
    setupMasterNode
    setupAgentNodes
    green_printf "$c node Cluster Configured Succesfully.\n"
    green_printf "Wait for few minutes for Nodes to be ready\n"
  elif [ "$1" == "down" ]
  then
    uninstallCluster
  fi
}
updateK8sVersion
$@


################################################
# authored by buncy.shaddai@oneconvergence.com #
################################################
