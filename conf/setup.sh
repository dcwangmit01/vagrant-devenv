set -x

# Disabling excess APT error messages from being shown
sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

# Setup Optional Git Configuration
if [ -f /vagrant/conf/dot.gitconfig ]; then
    sudo cp -f /vagrant/conf/dot.gitconfig /home/vagrant/.gitconfig
fi

# Setup Optional SSH Configuration
FROM_DIR=/vagrant/secrets/dot.ssh
TO_DIR=/home/vagrant/.ssh
if [ -f "${FROM_DIR}/id_rsa" ]; then
  sudo cp ${FROM_DIR}/id_rsa ${TO_DIR}/id_rsa
  sudo chmod 600 ${TO_DIR}/id_rsa
  sudo cat ${FROM_DIR}/id_rsa.pub >> ${TO_DIR}/authorized_keys
  sudo cp ${FROM_DIR}/id_rsa.pub ${TO_DIR}/id_rsa.pub
  sudo chown -R vagrant:vagrant ${TO_DIR}
fi

# Setup Optional AWS CLI Configuration
rm -rf /home/vagrant/.aws
ln -s /vagrant/secrets/dot.aws /home/vagrant/.aws

# Setup Optional Rackspace CLI Configuration
rm -rf /home/vagrant/.supernova
rm -rf /home/vagrant/.superglance
ln -s /vagrant/secrets/dot.rax/dot.supernova /home/vagrant/.supernova
ln -s /vagrant/secrets/dot.rax/dot.supernova /home/vagrant/.superglance

# copy .dot files over
cp dot.emacs /home/vagrant/.emacs
cp dot.screenrc /home/vagrant/.screenrc
sudo cp dot.emacs /root/.emacs
sudo cp dot.screenrc /root/.screenrc

# Upgrade
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

# add a few utils
sudo apt-get install -y mysql-client unzip dc
sudo apt-get install -y git bridge-utils traceroute nmap dhcpdump wget curl whois
sudo apt-get install -y emacs24-nox screen tree git
sudo apt-get install -y apache2-utils # for htpasswd
sudo apt-get install -y python-pip python-dev

# install AWS Command Line Interface: https://aws.amazon.com/cli/
if ! which aws; then
    sudo pip install awscli
fi

# install AWS ECS CLI
#  * http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
#  * The ecs-cli provides high level commands to ECS, while the "aws"
#      cli provides a lower level interface.
#  * For example, ecs-cli enables docker-compose
#  * Uses the same configuration file as the aws cli
if ! which ecs-cli; then
    sudo curl -s -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
    sudo chmod +x /usr/local/bin/ecs-cli
fi

# install docker
if ! which docker; then
    sudo curl -s https://get.docker.com/ | sudo sh
    sudo usermod -aG docker root
    sudo usermod -aG docker vagrant
fi

# install docker-compose
if ! which docker-compose; then
    sudo pip install -U docker-compose
fi

# install nova
if ! which nova; then
    sudo pip install rackspace-novaclient
fi

# install supernova
if ! which supernova; then
    sudo pip install supernova
    # supernova doesn't work unless we have more more recent version of python requests
    sudo pip install requests --upgrade
fi

# install superglance
if ! which superglance; then
    sudo apt-get install -y python-dev python-pip
    sudo apt-get install -y libffi-dev libssl-dev
    sudo pip install git+https://github.com/rtgoodwin/superglance.git@master
fi

# install python virtualenv
if ! which virtualenv; then
    sudo pip install virtualenv
fi

# install rack (command line client for managing rackspace cloud resources)
if ! which rack; then
    pushd /tmp
    wget --quiet https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.0.1/Linux/amd64/rack
    chmod a+x rack
    mkdir -p /usr/local/bin/
    mv rack /usr/local/bin/rack
    popd
fi

# install nodejs and npm
if ! which nodejs; then
    sudo apt-get -y install nodejs npm
fi

# Ensure user ownership
sudo chown -R vagrant:vagrant /home/vagrant

# install google cloud tools
if [ ! -f /home/vagrant/google-cloud-sdk/bin/gcloud ] ; then
    curl -s https://sdk.cloud.google.com | sudo -i -u vagrant \
      CLOUDSDK_CORE_DISABLE_PROMPTS=1 CLOUDSDK_INSTALL_DIR=/home/vagrant bash
    sudo -i -u vagrant ./google-cloud-sdk/bin/gcloud \
      config set disable_usage_reporting true
    sudo -i -u vagrant ./google-cloud-sdk/bin/gcloud \
      components install -q kubectl
fi

# install golang (binaries into /usr/local/go/bin)
if ! which go; then
    PACKAGE=go1.6.linux-amd64.tar.gz
    pushd /tmp
    wget -q https://storage.googleapis.com/golang/$PACKAGE
    tar -C /usr/local -xzf $PACKAGE
    rm -f $PACKAGE
    popd
fi

# install autoenv (will auto-execute any ".env" file in a parent dir)
if ! which activate.sh; then
    pip install autoenv
fi


# setup the .bashrc by appending the custom one
if [ -f /home/vagrant/.bashrc ] ; then
    # Truncates the Custom part of the config and below
    sed -n '/## Custom:/q;p' -i /home/vagrant/.bashrc
    # Appends custom bashrc
    cat /vagrant/conf/dot.bashrc >> /home/vagrant/.bashrc
fi

