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
apt-get -y install mysql-client unzip dc gnupg \
	git bridge-utils traceroute nmap dhcpdump wget curl siege whois \
	emacs24-nox screen tree git \
	apache2-utils \
	python-pip python-dev

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
if ! which go; then
    PACKAGE=go1.6.linux-amd64.tar.gz
    pushd .
    curl -s https://storage.googleapis.com/golang/$PACKAGE | tar -xz -C /usr/local
    popd
fi

# Install autoenv (will auto-execute any ".env" file in a parent dir)
#   Used by projects to auto-set GOPATH upon cd into directory.
if ! which activate.sh; then
    pip install autoenv
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
if ! screen -v | grep "4.03"; then
    TMP=/tmp/screen-install
    mkdir -p $TMP
    pushd $TMP
    wget http://ftp.us.debian.org/debian/pool/main/n/ncurses/libtinfo5_6.0+20160213-1_amd64.deb
    wget http://ftp.us.debian.org/debian/pool/main/s/screen/screen_4.3.1-2_amd64.deb
    dpkg -i *.deb
    rm -rf $TMP
    popd
fi

#####################################################################
# Configuration

# Setup the .bashrc by appending the custom one
if [ -f /home/vagrant/.bashrc ] ; then
    # Truncates the Custom part of the config and below
    sed -n '/## Custom:/q;p' -i /home/vagrant/.bashrc
    # Appends custom bashrc
    cat /vagrant/conf/dot.bashrc >> /home/vagrant/.bashrc
fi

# Setup Optional SSH Configuration
FROM_DIR=/vagrant/conf/dot.ssh.private
TO_DIR=/home/vagrant/.ssh
if [ -f "${FROM_DIR}/id_rsa" ]; then
  sudo cp ${FROM_DIR}/id_rsa ${TO_DIR}/id_rsa
  sudo chmod 600 ${TO_DIR}/id_rsa
  sudo cat ${FROM_DIR}/id_rsa.pub >> ${TO_DIR}/authorized_keys
  sudo cp ${FROM_DIR}/id_rsa.pub ${TO_DIR}/id_rsa.pub
  sudo chown -R vagrant:vagrant ${TO_DIR}
fi

# Setup Optional GNUPG Configuration
FROM_DIR=/vagrant/conf/dot.gnupg.private
TO_DIR=/home/vagrant/.gnupg
if [ ! -d "${TO_DIR}" ]; then
  cp -r ${FROM_DIR} ${TO_DIR}
  chmod 700 ${TO_DIR}
  chown -R vagrant:vagrant ${TO_DIR}
fi

# Setup Optional Git Configuration
if [ ! -f /vagrant/conf/dot.gitconfig.private ]; then
    ln -s /vagrant/conf/dot.gitconfig.private /home/vagrant/.gitconfig
fi

# Setup Optional Emacs Configuration
if [ ! -f /vagrant/conf/dot.emacs.private ]; then
    ln -s /vagrant/conf/dot.emacs.private /home/vagrant/.emacs
fi

# Setup Optional Screen Configuration
if [ ! -f /vagrant/conf/dot.screenrc.private ]; then
    ln -s /vagrant/conf/dot.screenrc.private /home/vagrant/.screenrc
fi

#####################################################################
# Cleanup

# Ensure user ownership
chown -R vagrant:vagrant /home/vagrant



#####################################################################
# Additionally, a whole bunch of things I may want to delete

# install rack (command line client for managing rackspace cloud resources)
if ! which rack; then
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

# install aws command line interface: https://aws.amazon.com/cli/
if ! which aws; then
    pip install awscli
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

# link .dot files over
rm -f /home/vagrant/.emacs
ln -s /vagrant/conf/dot.emacs /home/vagrant/.emacs
rm -f /home/vagrant/.screenrc
ln -s /vagrant/conf/dot.screenrc /home/vagrant/.screenrc
rm -f /home/vagrant/.bash_aliases
ln -s /vagrant/conf/dot.bash_aliases /home/vagrant/.bash_aliases

rm -f /root/.emacs
ln -s /vagrant/conf/dot.emacs /root/.emacs
rm -f /root/.screenrc
ln -s /vagrant/conf/dot.screenrc /root/.screenrc
rm -f /root/.bash_aliases
ln -s /vagrant/conf/dot.bash_aliases /root/.bash_aliases

# Setup Optional AWS CLI Configuration
rm -rf /home/vagrant/.aws
mkdir -p /home/vagrant/.aws
ln -s /vagrant/conf/dot.aws/credentials.private /home/vagrant/.aws/credentials

# Setup Optional Rackspace CLI Configuration
rm -f /home/vagrant/.supernova
ln -s /vagrant/conf/dot.rax/dot.supernova.private /home/vagrant/.supernova
rm -f /home/vagrant/.superglance
ln -s /vagrant/conf/dot.rax/dot.supernova.private /home/vagrant/.superglance

# Ensure user ownership
chown -R vagrant:vagrant /home/vagrant

