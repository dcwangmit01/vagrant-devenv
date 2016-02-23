FROM ubuntu:14.04

# stop warning messages from apt configuration on install
ENV TERM=linux
ENV DEBIAN_FRONTEND noninteractive

# install the program
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    sed -i 's/Port 22/Port 2022/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# set authorized_keys
COPY ./secrets/dot.ssh/id_rsa.pub /root/.ssh/authorized_keys

# expose the port (kube will fail if less than 1024)
EXPOSE 2022

# set the startup command
CMD ["/usr/sbin/sshd", "-D"]
