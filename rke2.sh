#!/bin/bash

function white_printf  { printf "\t\033[1;37m$@\033[0m";  }
function red_printf    { printf "\t\033[31m$@\033[0m";    }                                                               #
function green_printf  { printf "\t\033[32m$@\033[0m";    }                                                               #
function yellow_printf { printf "\t\033[33m$@\033[0m";    }

SSH_KEY=/home/ubuntu/keys/104/jenkins-rke.pem
SSH_USER=dkube
NODE=192.168.200.104


function setAgentConfig {
	white_printf	"Fetching token from Server Node......\n"
	token=$(ssh -i $SSH_KEY $SSH_USER@$NODE sudo cat /var/lib/rancher/rke2/server/node-token)
  	green_printf "Token fetched\n"
	cat config.yaml > agent-config.yaml
	echo server: https://$NODE:9345 >> agent-config.yaml
	echo token: $token >> agent-config.yaml
	green_printf "Configured agent-config.yaml.\n"
}

function installAgent {
	NODE=192.168.200.107
	scp -i $SHH_KEY ./agent-config  $SSH_USER@$NODE:/etc/rancher/rke2/config.yaml 
	ssh -i $SSH_KEY $SSH_USER@$NODE 'bash -s' < install.sh agent
}

setAgentConfig
installAgent
