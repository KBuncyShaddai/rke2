#!/bin/bash

#RKE2 Uninstall

sudo /usr/local/bin/rke2-killall.sh
sudo /usr/local/bin/rke2-uninstall.sh

#RKE2 Cleanup
curl -s https://raw.githubusercontent.com/rancherlabs/support-tools/master/extended-rancher-2-cleanup/extended-cleanup-rancher2.sh | sudo bash -i -f


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
helm ls --all --short | xargs -L1 helm delete --purge
sudo systemctl restart docker
sudo systemctl restart containerd

