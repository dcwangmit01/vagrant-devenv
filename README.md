# Personal Vagrant Development Environment

Creates a Vagrant machine running on OSX, with the following auto-installed and configured.

* Docker Tools: docker, docker-compose
* Kubernetes Tools: kubectl, minikube, helm, kops
* Cloud tools: Terraform
* Amazon AWS Cloud Tools: awscli, ecs-cli
* Google Cloud Tools: gcloud
* Vmware Tools: govc
* Languages: golang, nodejs
* Programming tools: hub, direnv, virtualenv, jinja2, yq, gitslave, emacs
* Network Tools: nmap, traceroute, whois
* Golang Tools: glide, protocol buffers

For your dotfiles and dotdirectories in `~/`, it creates files or directories
in /vagrant/custom, and then symbolically links from `~/`.  This ensures that
your configuration files are persisted on the host, between rebuilding of
vagrant machines.

# Preparing your box for Vagrant

## Preparing your box for Vagrant using Brew (the smart way!):

* Install Brew (http://brew.sh/)

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

* Install a few other packages

```
brew install git python wget curl gitslave brew-cask tree nmap ssh-copy-id
```

* Install vagrant and virtualbox

```
brew cask install virtualbox
brew cask install vagrant
```

* Install vbguest plugin (Optional)

Keeps virtualbox guest tools in sync with your version of virtualbox

```
vagrant plugin install vagrant-vbguest
```

* Install cachier plugin (caches the APT, download, and Maven resources so that the box builds faster)

```
vagrant plugin install vagrant-cachier
```

# Configure a few things (Recommended)

All of these will make your life easier:

### Configure Git Configuration (Optional)

Set defaults for your git configuration (email, name, aliases, etc)

Edit ~/.gitconfig, which is actually a symlink to /vagrant/custom/dot.gitconfig

```
[user]
	email = you@domain.com
	name = Firstname Lastname
```

### Configure Google Cloud and Container Engine (Optional)

```
# login to google cloud
gcloud auth login

# disable usage reporting to google
gcloud config set disable_usage_reporting true

# locate your project id
gcloud projects list

# set default project
gcloud config set core/project <project_id>

# locate your zone
gcloud compute zones list

# set default zone
gcloud config set compute/zone <zone_id>

# locate your cluster
gcloud container clusters list

# set default cluster
gcloud config set container/cluster <cluster_id>

# configure kubectl in google's environment
gcloud container clusters get-credentials <cluster_id>

# check your config
gcloud config list
```

### Configure AWS CLI Tools (Optional)

The pre-installed AWS cli commands require configuration to work.

Documentation for configuration is found here
[http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files](AWS
CLI Configuration)


Example ~/.aws/config file
```
[profile project_alpha]
output = json
region = us-west-1

[profile project_beta]
output = json
region = us-west-1
```

Example ~/.aws/credentials file
```
[project_alpha]
aws_access_key_id = <alpha_key_id>
aws_secret_access_key = <alpha_access_key>

[project_beta]
aws_access_key_id = <beta_key_id>
aws_secret_access_key = <beta_access_key>
```

Then, to switch between AWS accounts, set the right AWS_PROFILE environment variable.

```
export AWS_PROFILE=project_beta
```

### Configure Code Directory Mount from Host (Optional)

If you'd like to mount a directory from your host machine directly into the
vagrant machine, you may edit the synced folder directive in the Vagrant file.
The default will mount the host ~/Dev directory to the vagrant /vagrant/Dev directory.

```
# edit ./Vagrantfile if you have your directories to mount

    if File.directory?("~/Dev")
      dev.vm.synced_folder "~/Dev", "/vagrant/Dev"
    end
```


# Using this Vagrant image

## Start the virtual machine

```vagrant up```

## Connect to the machine

```vagrant ssh```

## Suspend the machine (so it doesn't eat into your battery life)

```vagrant suspend```

## Import your key to AWS (Optional)

Publish your keypair to every region in AWS that you will use

```
export KEY_NAME=${USER}
export PRIVATE_KEY="${HOME}/.ssh/id_rsa"
export PUBKEY_MATERIAL=`openssl rsa -in ${PRIVATE_KEY} -pubout 2>/dev/null|tail -n +2| head -n -1| tr -d '\n'`
export PROFILES='dev-us-west-1 dev-us-west-2 dev-us-east-1'
for i in ${PROFILES}; do
  aws ec2 delete-key-pair --profile=$i --key-name ${KEY_NAME};
  aws ec2 import-key-pair --profile=$i --key-name ${KEY_NAME} --public-key-material ${PUBKEY_MATERIAL};
done
```




