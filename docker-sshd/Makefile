
.PHONY: deps build install docker clean mrclean

# "export" allows Makefile targets to see these values (local to this Makefile)
# ?= means set only if no value
# without "export" makefile targets will not see these values
# set default tag to be last 8 chars hash of last git commit
export CONTAINER ?= docker-sshd
export VERSION ?= $(shell git log -1|grep commit|awk '{print $$2}'|tail -c 8|xargs)
export PROJECT ?= $(shell gcloud config list 2>/dev/null|grep project| cut -d'=' -f2| xargs)
export IMAGE ?= gcr.io/$(PROJECT)/$(CONTAINER):$(VERSION)

debug:
	@echo container: $(CONTAINER)
	@echo version: $(VERSION)
	@echo project: $(PROJECT)
	@echo image: $(IMAGE)

auth:
	gcloud auth login

docker-build:
	@# set the build context out one directory to access the secrets dir for ssh.pubkey
	docker build -t $(IMAGE) -f Dockerfile ../

docker-run:
	docker run --rm --name docker-sshd-run $(IMAGE)

docker-connect:
	@# connect to the existing running docker instance
	docker exec -it $(CONTAINER)-run /bin/bash

docker-run-bash:
	docker run --rm -i -t $(IMAGE) /bin/bash

docker-push: docker-build
	gcloud docker push $(IMAGE)

kube-create:
	@# replace the image before feeding to kubectl
	-sed "s|image:.*$$|image: $(IMAGE)|g" kube/sshd-rc.yaml | kubectl create -f -
	-kubectl create -f kube/sshd-svc.yaml

kube-delete:
	-kubectl delete -f kube/sshd-rc.yaml
	-kubectl delete -f kube/sshd-svc.yaml

