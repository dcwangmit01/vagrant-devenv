#!/bin/bash
set -euo pipefail

export KUBECONFIG=${KUBECONFIG:-$HOME/.kube/minikube}
export KUBEVERSION=${KUBEVERSION:-v1.10.0}

# sudo is default configured to drop this path
export PATH=$PATH:/usr/local/bin

# Minikube Enviroment Variables
#   https://github.com/kubernetes/minikube/blob/master/docs/env_vars.md
#   Code below taken from: https://github.com/kubernetes/minikube/blob/master/README.md
export MINIKUBE_HOME=${MINIKUBE_HOME:-$HOME/.minikube}
export MINIKUBE_WANTUPDATENOTIFICATION=${MINIKUBE_WANTUPDATENOTIFICATION:-false}
export MINIKUBE_WANTREPORTERRORPROMPT=${MINIKUBE_WANTREPORTERRORPROMPT:-false}
export MINIKUBE_WANTNONEDRIVERWARNING=false
export CHANGE_MINIKUBE_NONE_USER=true


# Bind-mount these paths to a common location which is more easily backed up
#   Tested to be unnecessary: "/var/lib/docker"
bind_dirs=( "/data" "/var/lib/localkube" \
    "/tmp/hostpath_pv" "/tmp/hostpath-provisioner" "/etc/kubernetes" \
    "$MINIKUBE_HOME" )
for bind_dir in "${bind_dirs[@]}"; do
    sudo mkdir -p $bind_dir
    sudo mkdir -p "/persist${bind_dir}"
    if ! (sudo mount | grep "/persist${bind_dir}" &>/dev/null); then
	sudo mount --bind "/persist${bind_dir}" $bind_dir
    fi
done

minikube start \
  --vm-driver=none \
  --kubernetes-version $KUBEVERSION \
  --apiserver-name localhost \
  --apiserver-ips 127.0.0.1 \
  --loglevel 1 \
  --v 2

# this for loop waits until kubectl can access the api server that Minikube has created
echo "Waiting for Minikube to become available"
for i in {1..150}; do # timeout for 5 minutes
  if ! kubectl get po &> /dev/null; then
    break
  fi
  sleep 2
done

# kubectl commands are now able to interact with Minikube cluster
echo "Minikube has successfully started"
