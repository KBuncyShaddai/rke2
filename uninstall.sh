#!/bin/bash

#RKE2 Uninstall


sudo /usr/local/bin/rke2-uninstall.sh
#sudo /usr/local/bin/rke2-killall.sh


#RKE2 Cleanup

systemctl stop rancher-system-agent.service
systemctl disable rancher-system-agent.service
rm -f /etc/systemd/system/rancher-system-agent.service
rm -f /etc/systemd/system/rancher-system-agent.env
systemctl daemon-reload
for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do sudo umount $mount; done
rm -f /usr/local/bin/rancher-system-agent
rm -rf /etc/rancher/
rm -rf /var/lib/rancher/
rm -rf /usr/local/bin/rke2*

#DOCKER CLEANUP

sudo docker rm -f $(sudo docker ps -qa)
sudo docker rmi -f $(sudo docker images -q)
sudo docker volume rm $(sudo docker volume ls -q)
#sudo reboot
for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do sudo umount $mount; done
sudo rm -rf /etc/ceph \
       /etc/cni \
       /etc/kubernetes \
       /opt/cni \
       /opt/rke \
       /run/secrets/kubernetes.io \
       /run/calico \
       /run/flannel \
       /var/lib/calico \
       /var/lib/etcd \
       /var/lib/cni \
       /var/lib/kubelet \
       /var/lib/rancher/rke/log \
       /var/log/containers \
       /var/log/kube-audit \
       /var/log/pods \
       /var/run/calico23
sudo rm -rf /etc/kubernetes/ /var/lib/kubelet/ /var/lib/etcd/
sudo docker system prune -f
sudo systemctl restart docker
sudo systemctl restart containerd

