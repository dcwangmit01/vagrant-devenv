#!/bin/bash

# Install docker
if ! which docker; then
    curl -fsSL https://get.docker.com/ | sh
    usermod -aG docker root
    usermod -aG docker vagrant
fi

# Install kubectl
if ! which kubectl; then
    curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x kubectl
fi

# Install minikube
if ! which minikube; then
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
fi

# Rewire minikube storage locations to ones that will survive reboots
sudo mkdir -p /persist
sudo mkdir -p /persist/data
sudo mkdir -p /persist/var/lib/localkube
sudo mkdir -p /persist/tmp/hostpath_pv
sudo mkdir -p /persist/tmp/hostpath-provisioner
sudo ln -sf /persist/data /
sudo ln -sf /persist/var/lib/localkube /var/lib/
sudo ln -sf /persist/tmp/hostpath_pv /tmp/
sudo ln -sf /persist/tmp/hostpath-provisioner /tmp/

# Set the persistent directory to be rw for all
sudo setfacl -R -m d:u::rwx /persist
sudo setfacl -R -m d:g::rwx /persist
sudo setfacl -R -m d:o::rwx /persist
sudo setfacl -R -m u::rwx /persist
sudo setfacl -R -m g::rwx /persist
sudo setfacl -R -m o::rwx /persist

# Taken from: https://github.com/kubernetes/minikube/blob/master/README.md
export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true

if [ ! -e $HOME/.kube ]; then
  mkdir -p $HOME/.kube
fi
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

sudo -E minikube start --vm-driver=none

# this for loop waits until kubectl can access the api server that Minikube has created
for i in {1..150}; do # timeout for 5 minutes
   kubectl get po &> /dev/null
   if [ $? -ne 1 ]; then
      break
  fi
  sleep 2
done

# kubectl commands are now able to interact with Minikube cluster
