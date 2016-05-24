set -x

# Ensure this script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

#####################################################################
# Setup Apt

# Disabling excess APT error messages from being shown
ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
dpkg-reconfigure debconf -f noninteractive -p critical

# set apt mirror at top of sources.list for faster downloads
if [ ! -f /etc/apt/sources.list.orig ]; then
    mv /etc/apt/sources.list /etc/apt/sources.list.orig
    echo "# Setting Mirrors" >> /etc/apt/sources.list
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-security main restricted universe multiverse" >> /etc/apt/sources.list
    echo "" >> /etc/apt/sources.list
    cat /etc/apt/sources.list.orig >> /etc/apt/sources.list
    # workaround bug: https://bugs.launchpad.net/ubuntu/+source/apt/+bug/1479045
    rm -f /var/lib/apt/lists/partial/*
    apt-get clean
fi

#####################################################################
# Setup Operating System and base utils from apt

# Upgrade OS
apt-get update
apt-get -y autoremove
apt-get -y upgrade

# Add common Utils
# 
# moreutils: for sponge
# apache2-utils: for htpasswd
apt-get -y install mysql-client unzip dc gnupg moreutils \
	git bridge-utils traceroute nmap dhcpdump wget curl siege whois \
	emacs24-nox screen tree git \
	apache2-utils \
	python-pip python-dev

#####################################################################
# Configuration
#   Do this before tool installation to ensure symlinks can be created
#   before written to)

# Setup the .bashrc by appending the custom one
if [ -f /home/vagrant/.bashrc ] ; then
    # Truncates the Custom part of the config and below
    sed -n '/## Custom:/q;p' -i /home/vagrant/.bashrc
    # Appends custom bashrc
    cat /vagrant/conf/dot.bashrc >> /home/vagrant/.bashrc
    # Running this script as root, so must use user's point of view
    source /home/vagrant/.bashrc
fi

# Copy or Link Optional SSH Configuration
FROM_DIR=/vagrant/conf/dot.ssh.private
TO_DIR=/home/vagrant/.ssh
if [ -d "${FROM_DIR}" ]; then
    if [ -f "${FROM_DIR}/id_rsa.pub" ]; then
	rm -f ${TO_DIR}/id_rsa.pub
	ln -s ${FROM_DIR}/id_rsa.pub ${TO_DIR}/id_rsa.pub
	if ! grep "`cat ${FROM_DIR}/id_rsa.pub`" ${TO_DIR}/authorized_keys; then
	    cat ${FROM_DIR}/id_rsa.pub >> ${TO_DIR}/authorized_keys
	fi
    fi
    if [ -f "${FROM_DIR}/config" ]; then
	rm -f ${TO_DIR}/config
	ln -s ${FROM_DIR}/config ${TO_DIR}/config
    fi
    if [ -f "${FROM_DIR}/known_hosts" ]; then
	rm -f ${TO_DIR}/known_hosts
	ln -s ${FROM_DIR}/known_hosts ${TO_DIR}/known_hosts
    fi
    chown -R vagrant:vagrant ${TO_DIR}
    chmod -R 700 ${TO_DIR}

#    Staging the private key should not be necessary if using ssh-agent
#    if [ -f "${FROM_DIR}/id_rsa" ]; then
#	rm -f ${TO_DIR}/id_rsa
#	ln -s ${FROM_DIR}/id_rsa ${TO_DIR}/id_rsa
#	chmod 600 ${TO_DIR}/id_rsa
#    fi
fi

# Setup Optional AWS CLI Configuration
FROM_DIR=/vagrant/conf/dot.aws.private
TO_DIR=/home/vagrant/.aws
if [ -d $FROM_DIR ] && [ ! -e $TO_DIR ]; then
    mkdir -p `dirname $TO_DIR`
    ln -s $FROM_DIR $TO_DIR
fi

# Setup Optional GNUPG Configuration
#   This is necessary unless you want to do ssh latest-version hackery
#   to enable gpg-agent socket forwarding.
FROM_DIR=/vagrant/conf/dot.gnupg.private
TO_DIR=/home/vagrant/.gnupg
if [ -d $FROM_DIR ] && [ ! -e $TO_DIR ]; then
    mkdir -p `dirname $TO_DIR`
    ln -s $FROM_DIR $TO_DIR
fi

# Setup Optional Gcloud Config
FROM_DIR=/vagrant/conf/dot.gcloud.private
TO_DIR=/home/vagrant/.config/gcloud
if [ -d $FROM_DIR ] && [ ! -e $TO_DIR ]; then
    mkdir -p `dirname $TO_DIR`
    ln -s $FROM_DIR $TO_DIR
fi

# Setup Optional Kube Config
FROM_DIR=/vagrant/conf/dot.kube.private
TO_DIR=/home/vagrant/.kube
if [ -d $FROM_DIR ] && [ ! -e $TO_DIR ]; then
    mkdir -p `dirname $TO_DIR`
    ln -s $FROM_DIR $TO_DIR
fi

# Setup Optional Git Configuration
if [ -f /vagrant/conf/dot.gitconfig.private ]; then
    ln -s /vagrant/conf/dot.gitconfig.private /home/vagrant/.gitconfig
fi

# Setup Optional Emacs Configuration
if [ -f /vagrant/conf/dot.emacs.private ]; then
    ln -s /vagrant/conf/dot.emacs.private /home/vagrant/.emacs
fi

# Setup Optional Screen Configuration
if [ -f /vagrant/conf/dot.screenrc.private ]; then
    ln -s /vagrant/conf/dot.screenrc.private /home/vagrant/.screenrc
fi

#####################################################################
# Install Miscellaneous Tools

# Install docker
if ! which docker; then
    curl -s https://get.docker.com/ | sh
    usermod -aG docker root
    usermod -aG docker vagrant
fi

# Install docker-compose
if ! which docker-compose; then
    pip install -U docker-compose
fi

# Install google cloud tools and kubernetes
if [ ! -f /home/vagrant/google-cloud-sdk/bin/gcloud ] ; then
    curl -s https://sdk.cloud.google.com | sudo -i -u vagrant \
      CLOUDSDK_CORE_DISABLE_PROMPTS=1 CLOUDSDK_INSTALL_DIR=/home/vagrant bash
    sudo -i -u vagrant ./google-cloud-sdk/bin/gcloud \
      config set disable_usage_reporting true
    sudo -i -u vagrant ./google-cloud-sdk/bin/gcloud \
      components install -q kubectl
fi

# Install golang into /usr/local/go/bin (requires .bashrc to set path)
if [ ! -f /usr/local/go/bin/go ]; then
    PACKAGE=go1.6.linux-amd64.tar.gz
    pushd .
    curl -s https://storage.googleapis.com/golang/$PACKAGE | tar -xz -C /usr/local
    popd
fi

# install aws command line interface: https://aws.amazon.com/cli/
if ! which aws; then
    pip install awscli
fi

# Install direnv
if ! which direnv; then
    TMP=/tmp/direnv-install
    mkdir -p $TMP
    pushd $TMP
    wget http://ftp.us.debian.org/debian/pool/main/d/direnv/direnv_2.7.0-1_amd64.deb
    dpkg -i *.deb
    rm -rf $TMP
    popd
fi

# Install python virtualenv
if ! which virtualenv; then
    pip install virtualenv
fi

# install python jinja2 cli tool
if ! which j2; then
    pip install j2cli
fi

# install yq: a yaml cli editor
if ! which yq; then
    curl -s https://raw.githubusercontent.com/dcwangmit01/yq/master/install.sh | bash
fi

# install secure: a gpg multiparty encryption wrapper
if ! which secure; then
    curl -s https://raw.githubusercontent.com/dcwangmit01/secure/master/install.sh | bash
fi

# Install a more recent version of screen that supports vertical split
if ! screen -v | grep "4.02"; then
    TMP=/tmp/screen-install
    mkdir -p $TMP
    pushd $TMP
    wget http://mirrors.kernel.org/ubuntu/pool/main/s/screen/screen_4.2.1-2~ubuntu14.04.1_amd64.deb
    dpkg -i *.deb
    rm -rf $TMP
    popd
fi

# Install gitslave
if ! which gits; then
    # Use a forked version of gitslave because it hasn't been updated
    # in a long time, and commands like "gits status" no longer work
    # with more recent versions of git.
    TMP=/tmp/gitslave-install
    mkdir -p $TMP
    pushd $TMP
    git clone https://github.com/joelpurra/gitslave.git
    cd gitslave
    make install
    popd
    rm -rf $TMP
fi

# Install Terraform from Hashicorp
if [ ! -f /usr/local/terraform/bin/terraform ]; then
    VERSION=0.6.15
    DIR=/usr/local/terraform/bin
    mkdir -p $DIR
    pushd $DIR
    if [ ! -f terraform_${VERSION}_linux_amd64.zip ]; then
	curl -s https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip > terraform_${VERSION}_linux_amd64.zip
    fi
    unzip terraform_${VERSION}_linux_amd64.zip
    popd
fi

# Install Ansible
if ! which ansible; then
    apt-add-repository -y ppa:ansible/ansible
    apt-get update
    apt-get -y install ansible python-netaddr
fi

#####################################################################
# Cleanup

# Ensure user ownership
chown -R vagrant:vagrant /home/vagrant

#####################################################################
# Additionally, a whole bunch of things I may want to delete

# install rack (command line client for managing rackspace cloud resources)
if [ ! -f /usr/local/bin/rack ]; then
    mkdir -p /usr/local/bin
    wget --quiet https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.0.1/Linux/amd64/rack \
	 -O /usr/local/bin/rack
    chmod a+x rack
fi

# install nova
if ! which nova; then
    pip install rackspace-novaclient
fi

# install supernova
if ! which supernova; then
    pip install supernova
    # supernova doesn't work unless we have more more recent version of python requests
    pip install requests --upgrade
fi

# install superglance
if ! which superglance; then
    apt-get -y install -y python-dev python-pip libffi-dev libssl-dev
    pip install git+https://github.com/rtgoodwin/superglance.git@master
fi

# install aws ecs cli
#  * http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
#  * The ecs-cli provides high level commands to ECS, while the "aws"
#      cli provides a lower level interface.
#  * For example, ecs-cli enables docker-compose
#  * Uses the same configuration file as the aws cli
if ! which ecs-cli; then
    curl -s -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
    chmod +x /usr/local/bin/ecs-cli
fi

# install nodejs and npm
if ! which nodejs; then
    apt-get -y install nodejs npm
    ln -s /usr/bin/nodejs /usr/bin/node
fi

# Setup Optional Bash Aliases Custom Configuration
if [ -f /vagrant/conf/.bash_aliases ]; then
    ln -s /vagrant/conf/dot.bash_aliases /home/vagrant/.bash_aliases
fi

# Setup Optional Rackspace CLI Configuration
rm -f /home/vagrant/.supernova
ln -s /vagrant/conf/dot.rax/dot.supernova.private /home/vagrant/.supernova
rm -f /home/vagrant/.superglance
ln -s /vagrant/conf/dot.rax/dot.supernova.private /home/vagrant/.superglance

# Ensure user ownership
chown -R vagrant:vagrant /home/vagrant

