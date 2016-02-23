
.PHONY: deps build install docker clean mrclean

docker:
	:# set the build context out one directory to access the secrets dir
	docker build -t docker-sshd -f Dockerfile ../

docker-run:
	docker run --rm --name docker-sshd-run docker-sshd

docker-run-bash:
	docker run -i -t docker-sshd /bin/bash
