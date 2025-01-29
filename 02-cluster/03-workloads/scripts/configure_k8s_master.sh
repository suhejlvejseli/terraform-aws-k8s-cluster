#!/bin/bash

######### ** FOR MASTER NODE ** #########

hostname k8s-master-node
echo "k8s-master-node" > /etc/hostname

sudo su

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install unzip
unzip awscliv2.zip
sudo ./aws/install

sudo swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sysctl --system

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

apt-get update
apt-get -y install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
sudo apt-get update
sudo apt-get -y install containerd.io
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" "/etc/containerd/config.toml"
sudo systemctl restart containerd
sudo systemctl status containerd

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo gpg -dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes tools
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet 

export ipaddr=`ip address|grep enX0|grep inet|awk -F ' ' '{print $2}' |awk -F '/' '{print $1}'`
export pubip=`dig +short myip.opendns.com @resolver1.opendns.com`

# Initialize the Kubernetes cluster 
kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/restult.out

cat /tmp/restult.out

#to get join commdn
tail -2 /tmp/restult.out > /tmp/join_command.sh;
aws s3 cp /tmp/join_command.sh s3://${s3_bucket_name};

#Add kube config to root user.
mkdir -p /root/.kube;
cp -i /etc/kubernetes/admin.conf /root/.kube/config;
cp -i /etc/kubernetes/admin.conf /tmp/admin.conf;
chmod 755 /tmp/admin.conf

#Add kube config to ubuntu user.
mkdir -p /home/ubuntu/.kube;
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config;
chmod 755 /home/ubuntu/.kube/config

export KUBECONFIG=/root/.kube/config

#to copy kube config file to s3 
cp /etc/kubernetes/admin.conf /home/ubuntu/
sed -i "s/https:\/\/$ipaddr:6443/https:\/\/$pubip:6443/" /home/ubuntu/admin.conf
aws s3 cp /home/ubuntu/admin.conf s3://${s3_bucket_name}

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
bash get_helm.sh

# Setup flannel
kubectl create --kubeconfig /root/.kube/config ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel --set podCidr="192.168.0.0/16" --namespace kube-flannel flannel/flannel

# Configure dynamic storageclass 
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml