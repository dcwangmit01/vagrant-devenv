#!/bin/bash
set -x
set -euo pipefail

# Ensure this script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

CACHE_DIR=/vagrant/.cache
mkdir -p $CACHE_DIR

#####################################################################
# Persist the configuration directories for several tools
declare -A from_to_dirs
from_to_dirs=( \
    ["/vagrant/custom/dot.ssh"]="/home/vagrant/.ssh" \
    ["/vagrant/custom/dot.aws"]="/home/vagrant/.aws" \
    ["/vagrant/custom/dot.emacs.d"]="/home/vagrant/.emacs.d" \
    ["/vagrant/custom/dot.gnupg"]="/home/vagrant/.gnupg" \
    ["/vagrant/custom/dot.gcloud"]="/home/vagrant/.config/gcloud" \
    ["/vagrant/custom/dot.kube"]="/home/vagrant/.kube" )
for from_dir in "${!from_to_dirs[@]}"; do
    to_dir=${from_to_dirs[$from_dir]}
    # Ensure custom config directory exists
    if [ ! -d "${from_dir}" ]; then
        mkdir -p ${from_dir}
    fi
    # Set link to the custom config directory
    if [ ! -e $to_dir ]; then
        mkdir -p `dirname $to_dir`
        ln -s $from_dir $to_dir
    fi
done

# Persist the configuration files for several tools
declare -A from_to_files
from_to_files=( \
    ["/vagrant/custom/00aptproxy"]="/etc/apt/apt.conf.d/00aptproxy" \
    ["/vagrant/custom/dot.gitconfig"]="/home/vagrant/.gitconfig" \
    ["/vagrant/custom/dot.hub"]="/home/vagrant/.config/hub" \
    ["/vagrant/custom/dot.emacs"]="/home/vagrant/.emacs" \
    ["/vagrant/custom/dot.vimrc"]="/home/vagrant/.vimrc" \
    ["/vagrant/custom/dot.screenrc"]="/home/vagrant/.screenrc" )
for from_file in "${!from_to_files[@]}"; do
    to_file=${from_to_files[$from_file]}
    # Ensure custom config file exists and is empty
    if [ ! -f ${from_file} ]; then
        mkdir -p `dirname $from_file`
        touch $from_file
    fi
    # Set link to the custom config file
    if [ ! -L $to_file ] || [ ! -e $to_file ]; then
        rm -f $to_file
        mkdir -p `dirname $to_file`
        ln -s $from_file $to_file
    fi
done

#####################################################################
# Setup Operating System and base utils from apt

# Upgrade OS
apt-get update
apt-get -y autoremove

# Add common Utils
#
# moreutils: for sponge
# apache2-utils: for htpasswd
# xauth: to forward X11 programs to the host machine
apt-get -yq install mysql-client unzip dc gnupg moreutils \
    git bridge-utils traceroute nmap dhcpdump wget curl siege whois \
    emacs24-nox screen tree git \
    apache2-utils \
    python-pip python-dev \
    xauth qemu-user-static

#####################################################################
# Configuration
#   Do this before tool installation to ensure symlinks can be created
#   before written to)


declare -A owner_to_home
owner_to_home=( \
    ["root"]="/root" \
    ["vagrant"]="/home/vagrant" )
for owner in "${!owner_to_home[@]}"; do
    home=${owner_to_home[$owner]}
    bashrc=$home/.bashrc

    # Setup the .bashrc by appending the custom one
    if [ -f $bashrc ] ; then
	# Truncates the Custom part of the config and below
	sed -n '/## Custom:/q;p' -i $bashrc
	# Appends custom bashrc
	cat /vagrant/custom/dot.bashrc >> $bashrc
	# ensure ownership
	chown $owner:$owner $bashrc
    fi
done

# Running this script as root, so must use user's point of view
source /home/vagrant/.bashrc

#####################################################################
# Install Miscellaneous Tools

# Install docker
if ! which docker; then
    curl -fsSL https://get.docker.com/ | sh
    usermod -aG docker root
    usermod -aG docker vagrant
fi

# Install docker-compose
if ! which docker-compose; then
    pip install -U docker-compose
fi

# Install google cloud tools and kubectl
if [ ! -f /usr/local/google-cloud-sdk/bin/gcloud ] ; then
  curl -fsSL https://sdk.cloud.google.com | sudo -i -u root \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 CLOUDSDK_INSTALL_DIR=/usr/local bash
  /usr/local/google-cloud-sdk/bin/gcloud \
    config set disable_usage_reporting true
  /usr/local/google-cloud-sdk/bin/gcloud \
    components install -q kubectl
fi

# Install golang into /usr/local/go/bin (requires .bashrc to set path)
if [ ! -f /usr/local/go/bin/go ]; then
    PACKAGE=go1.7.5.linux-amd64.tar.gz
    if [ ! -f $CACHE_DIR/$PACKAGE ]; then
        curl -fsSL https://storage.googleapis.com/golang/$PACKAGE > $CACHE_DIR/$PACKAGE
    fi
    tar -xzf $CACHE_DIR/$PACKAGE -C /usr/local
fi

# Setup the system GOPATH directory
if [ ! -d /go ]; then
    mkdir /go
    # ensure admin group (which includes vagrant user) has access
    chown root:adm /go
    # ensure future files created inherit group permissions
    find /go -type d -print0 | xargs -0 chmod g+rws
fi

# Install github "hub" command
if ! which hub; then
    go get -u github.com/github/hub
fi

# Install direnv
if ! which direnv; then
    PACKAGE=direnv_2.7.0-1_amd64.deb
    if [ ! -f $CACHE_DIR/$PACKAGE ]; then
        curl -fsSL http://mirrors.kernel.org/ubuntu/pool/universe/d/direnv/$PACKAGE > $CACHE_DIR/$PACKAGE
    fi
    dpkg -i $CACHE_DIR/$PACKAGE
fi

# Install python virtualenv, also upgrade pip
if ! which virtualenv; then
    pip install --upgrade pip
    pip install virtualenv
fi

# install python jinja2 cli tool
if ! which j2; then
    pip install j2cli
fi

# install yq: a yaml cli editor
if ! which yq; then
    curl -fsSL https://raw.githubusercontent.com/dcwangmit01/yq/master/install.sh | bash
fi

# install secure: a gpg multiparty encryption wrapper
if ! which secure; then
    curl -fsSL https://raw.githubusercontent.com/dcwangmit01/secure/master/install.sh | bash
fi

# Install gitslave
if ! which gits; then
    # Use a forked version of gitslave because it hasn't been updated
    # in a long time, and commands like "gits status" no longer work
    # with more recent versions of git.
    if [ ! -d $CACHE_DIR/gitslave ]; then
      pushd $CACHE_DIR
      git clone https://github.com/joelpurra/gitslave.git
      popd
    fi
    pushd $CACHE_DIR/gitslave
    make install
    popd
fi

# install npm and nodejs
if ! which npm; then
    apt-get -yq install nodejs npm
    ln -s /usr/bin/nodejs /usr/bin/node
fi

# install github/electron
if ! which electron; then
    apt-get -yq install libgtk2.0-0 libxtst6 libxss1 libgconf-2-4 libnss3

    PACKAGE=electron-v1.4.15-linux-x64.zip
    URL=https://github.com/electron/electron/releases/download/v1.4.15/electron-v1.4.15-linux-x64.zip
    if [ ! -f $CACHE_DIR/$PACKAGE ]; then
        curl -fsSL $URL > $CACHE_DIR/$PACKAGE
    fi
    unzip -d /usr/local/electron-v1.4.15 $CACHE_DIR/$PACKAGE
    ln -s /usr/local/electron-v1.4.15/electron /usr/local/bin/electron
fi


#####################################################################
# Cleanup

# Ensure user ownership
if [ ! -f /home/vagrant/.setup/chowned ] ; then
    chown -R vagrant:vagrant /home/vagrant
    mkdir -p /home/vagrant/.setup
    touch /home/vagrant/.setup/chowned
fi

#####################################################################
# Additionally, a whole bunch of things I may want to delete

# # Install Terraform from Hashicorp
# if [ ! -f /usr/local/terraform/bin/terraform ]; then
#   VERSION=0.7.3
#   CACHE_DIR=/vagrant/.cache
#   DIR=/usr/local/terraform/bin
#   mkdir -p $CACHE_DIR
#   mkdir -p $DIR
#   pushd $CACHE_DIR
#     if [ ! -f terraform_${VERSION}_linux_amd64.zip ]; then
#       curl -fsSL \
#         https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip \
#       > terraform_${VERSION}_linux_amd64.zip
#     fi
#     pushd $DIR
#       cp $CACHE_DIR/terraform_${VERSION}_linux_amd64.zip .
#       unzip terraform_${VERSION}_linux_amd64.zip
#     popd
#   popd
# fi

# install aws command line interface: https://aws.amazon.com/cli/
#if ! which aws; then
#    pip install awscli
#fi

