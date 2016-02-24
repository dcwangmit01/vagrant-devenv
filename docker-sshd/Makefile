
.PHONY: deps build install docker clean mrclean

# ?= means set only if no value
# set default tag to be last 8 chars hash of Dockerfile

CONTAINER ?= docker-sshd
VERSION ?= $(shell shasum Dockerfile |awk '{print $$1}'|tail -c 8|xargs)
PROJECT ?= $(shell gcloud config list 2>/dev/null|grep project| cut -d'=' -f2| xargs)
IMAGE ?= gcr.io/$(PROJECT)/$(CONTAINER):$(VERSION)

env:
	@echo container: $(CONTAINER)
	@echo version: $(VERSION)
	@echo project: $(PROJECT)
	@echo image: $(IMAGE)
	@echo tag: $(TAG)

auth:
	gcloud auth login

docker:
	@# set the build context out one directory to access the secrets dir
	docker build -t $(IMAGE) -f Dockerfile ../

docker-run:
	docker run --rm --name docker-sshd-run $(IMAGE)

docker-connect:
	@# connect to the existing running docker instance
	docker exec -it docker-sshd-run /bin/bash

docker-run-bash:
	docker run --rm -i -t $(IMAGE) /bin/bash

docker-push:
	gcloud docker push $(IMAGE)
