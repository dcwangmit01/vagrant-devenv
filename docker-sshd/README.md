# Instructions

This will create docker container that you can ssh into for debugging
and kubernetes environment exploration.  I use it as a disposable VM
when I need to investigate the environment of a container inside a
kubernetes pod.  Better ways to do this are to use "kubectl
port-forward" and "kubectl exec".  However, using this container
allows scp'ing without hacking.

```
# (Optional) Set your buildenv varibles to override default Makefile Vars
# Check the Makefile for defaults
export CONTAINER=docker-sshd
export VERSION=`shasum Dockerfile |awk '{print $1}'|tail -c 8|xargs`
export PROJECT=`gcloud config list 2>/dev/null|grep project| cut -d'=' -f2| xargs`
export IMAGE=gcr.io/${PROJECT}/${CONTAINER}:${VERSION}

# Create the docker image
make docker-build

# Push the docker image to Google Container Registry
make docker-push

# Delete any existing Kubernetes Replication Controllers and Services
make kube-delete

# Create the Kubernetes
make kube-create

# Check status
kubectl get rc,svc,po
```

