set -x

# set apt mirror at top of sources.list for faster downloads
if [ ! -f /etc/apt/sources.list.orig ]; then
    sudo mv /etc/apt/sources.list /etc/apt/sources.list.orig
    echo "# Setting Mirrors" | sudo tee -a /etc/apt/sources.list > /dev/null
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise main restricted universe multiverse" | sudo tee -a  /etc/apt/sources.list > /dev/null
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list > /dev/null
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list > /dev/null
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-security main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list > /dev/null
    echo "" | sudo tee -a /etc/apt/sources.list > /dev/null
    cat /etc/apt/sources.list.orig | sudo tee -a /etc/apt/sources.list > /dev/null
    # workaround bug: https://bugs.launchpad.net/ubuntu/+source/apt/+bug/1479045
    sudo rm -f /var/lib/apt/lists/partial/*
    sudo apt-get clean
fi

# Disabling excess APT error messages from being shown
sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

# Upgrade
sudo apt-get update
sudo apt-get -y autoremove
sudo apt-get -y upgrade

# add a few utils
sudo apt-get install -y mysql-client unzip dc gnupg
sudo apt-get install -y git bridge-utils traceroute nmap dhcpdump wget curl whois
sudo apt-get install -y emacs24-nox screen tree git moreutils
sudo apt-get install -y apache2-utils # for htpasswd
sudo apt-get install -y python-pip python-dev

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

# install python virtualenv
if ! which virtualenv; then
    sudo pip install virtualenv
fi

# install python jinja cli tool
if ! which j2; then
    sudo pip install j2cli # a jinja2 cli tool
fi

# install yq: a cli yaml editor
if ! which yq; then
    curl -s https://raw.githubusercontent.com/dcwangmit01/yq/master/install.sh | sudo bash
fi

# install secure: a gpg multiparty encryption wrapper
if ! which secure; then
    curl -s https://raw.githubusercontent.com/dcwangmit01/secure/master/install.sh | sudo bash
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

# install aws command line interface: https://aws.amazon.com/cli/
if ! which aws; then
    sudo pip install awscli
fi

# install aws ecs cli
#  * http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
#  * The ecs-cli provides high level commands to ECS, while the "aws"
#      cli provides a lower level interface.
#  * For example, ecs-cli enables docker-compose
#  * Uses the same configuration file as the aws cli
if ! which ecs-cli; then
    sudo curl -s -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
    sudo chmod +x /usr/local/bin/ecs-cli
fi

# install nodejs and npm
if ! which nodejs; then
    sudo apt-get -y install nodejs npm
    sudo ln -s /usr/bin/nodejs /usr/bin/node
fi

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
if [ ! -f /usr/local/go/bin/go ]; then
    PACKAGE=go1.6.linux-amd64.tar.gz
    pushd /tmp
    wget -q https://storage.googleapis.com/golang/$PACKAGE
    sudo tar -C /usr/local -xzf $PACKAGE
    rm -f $PACKAGE
    popd
fi

# install autoenv (will auto-execute any ".env" file in a parent dir)
if ! which activate.sh; then
    sudo pip install autoenv
fi

# Install a more recent version of screen that supports vertical split
if ! screen -v | grep "4.03"; then
    pushd /tmp
    wget http://ftp.us.debian.org/debian/pool/main/n/ncurses/libtinfo5_6.0+20160213-1_amd64.deb
    sudo dpkg -i libtinfo5_6.0+20160213-1_amd64.deb
    wget http://ftp.us.debian.org/debian/pool/main/s/screen/screen_4.3.1-2_amd64.deb
    sudo dpkg -i screen_4.3.1-2_amd64.deb
    rm libtinfo*.deb screen*.deb
    popd
fi

# setup the .bashrc by appending the custom one
if [ ! -f /home/vagrant/.bashrc.orig ]; then
    sudo cp /home/vagrant/.bashrc /home/vagrant/.bashrc.orig
    # Truncates the Custom part of the config and below
    sudo sed -n '/## Custom:/q;p' -i /home/vagrant/.bashrc
    # Appends custom bashrc
    cat /vagrant/conf/dot.bashrc | sudo tee -a /home/vagrant/.bashrc > /dev/null
fi

# Setup Optional Bash Aliases Custom Configuration
if [ -f /vagrant/conf/.bash_aliases ]; then
    sudo ln -s /vagrant/conf/dot.bash_aliases /home/vagrant/.bash_aliases
fi

# link .dot files over
sudo rm -f /home/vagrant/.emacs
sudo ln -s /vagrant/conf/dot.emacs /home/vagrant/.emacs
sudo rm -f /home/vagrant/.screenrc
sudo ln -s /vagrant/conf/dot.screenrc /home/vagrant/.screenrc
sudo rm -f /home/vagrant/.bash_aliases
sudo ln -s /vagrant/conf/dot.bash_aliases /home/vagrant/.bash_aliases

sudo rm -f /root/.emacs
sudo ln -s /vagrant/conf/dot.emacs /root/.emacs
sudo rm -f /root/.screenrc
sudo ln -s /vagrant/conf/dot.screenrc /root/.screenrc
sudo rm -f /root/.bash_aliases
sudo ln -s /vagrant/conf/dot.bash_aliases /root/.bash_aliases

# Setup Optional Git Configuration
if [ -f /vagrant/conf/dot.gitconfig.private ]; then
    sudo ln -s /vagrant/conf/dot.gitconfig.private /home/vagrant/.gitconfig
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
sudo chown -R vagrant:vagrant /home/vagrant

