# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  # config.vm.box = "ubuntu/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL

  #####################################################################
  # Custom Configuration

  # TODO: http://ermaker.github.io/blog/2015/11/18/change-insecure-key-to-my-own-key-on-vagrant.html

  # Enable ssh forwarding for ssh-agent
  config.ssh.forward_x11 = true
  config.ssh.forward_agent = true

  config.vm.define "dev" do |dev|
    dev.vm.hostname = "devenv"
    $network_type = "private"  # valid values are "public" or "private".  Private uses NAT
    $address = "192.168.3.13"  # ignored when network_type=="private"
    $gateway = "192.168.3.1"   # ignored when network_type=="private"
    $interface = "eth1"
    $bridge = "en0: Ethernet"

    dev.vm.box = "bento/ubuntu-16.04"

    # if File.directory?("~/Dev")
    #   dev.vm.synced_folder "~/Dev", "/vagrant/Dev"
    # end
    # custom: above does not work for symlinks
    dev.vm.synced_folder "~/Dev", "/home/vagrant/Dev"
    dev.vm.synced_folder "./backup", "/backup"

    # dev (minikube doesn't seem to want to run with this.  Retest later)
    # dev.vm.synced_folder "./persist/data", "/data"
    # dev.vm.synced_folder "./persist/var/lib/localkube", "/var/lib/localkube"
    # dev.vm.synced_folder "./persist/tmp/hostpath_pv", "/tmp/hostpath_pv"
    # dev.vm.synced_folder "./persist/tmp/hostpath-provisioner", "/tmp/hostpath-provisioner"

    # Network Configuration (setups up eth1, eth0 remains NAT)
    if $network_type == "public"
      dev.vm.network "public_network",
                      bridge: [$bridge],
                      ip: $address
    else  # network_type == "private"
      # Only forward host ports to vagrant machine ports for private networks
      dev.vm.network "forwarded_port", guest: 80, host: 8080
      dev.vm.network "forwarded_port", guest: 443, host: 8443
      dev.vm.network "forwarded_port", guest: 5000, host: 5000
      dev.vm.network "forwarded_port", guest: 10080, host: 10080
    end

    dev.vm.provider "virtualbox" do |vb, override|
      override.vm.box = "bento/ubuntu-16.04"
      #override.vm.box_version = "2.2.9"
      vb.gui = false
      vb.memory = "4096"
    end

    dev.vm.provision "shell",
                        run: "always",
                        args: [ $gateway, $interface, $network_type ],
                        inline: <<-SHELL
      set -euo pipefail
      pushd /vagrant/conf
      chmod 755 setup.sh && ./setup.sh 2>&1 | tee /tmp/install.log
      popd

      if [ "$3" == "public" ]; then
        # add the direct default gateway
        route add default gw $1 $2
        # remove the NAT default gateway
        eval `route -n | awk '{ if ($8 =="eth0" && $2 != "0.0.0.0") print "route del default gw " $2; }'`
      fi
    SHELL

    # Install the caching plugin if you want to take advantage of the cache
    # $ vagrant plugin install vagrant-cachier
    if Vagrant.has_plugin?("vagrant-cachier")
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      config.cache.scope = :machine
    else
      puts "[-] WARN: Subsequent provisions will be much faster"
      puts "    if you install vagrant-cachier:"
      puts "  vagrant plugin install vagrant-cachier"
    end
  end
end
