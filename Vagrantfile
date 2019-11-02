Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true                           # Update /etc/hosts with entries from other VMs
  config.hostmanager.manage_host = false                      # Don't update /etc/hosts on the Hypervisor
  config.hostmanager.include_offline = true                   # Also document offline VMs
  config.vm.define "server" do |server|
    server.vm.box = "centos/7"                                # base image we use
    server.vm.hostname = "prometheus"                         # hostname that's configured within the VM
    server.vm.network "private_network", ip: "192.168.33.10"
    config.vm.network "forwarded_port", guest: 9090, host: 9090
    server.vm.provider "virtualbox" do |v|
      v.name = "server"                                       # Name that's displayed within the VirtualBox UI
      v.memory = 3072                                         # Ram in MB
      v.cpus = 2                                              # Cores
    end

    server.vm.provision "shell", inline: <<-SHELL
      yum install --assumeyes https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
      yum install --assumeyes puppet puppetserver
      source /etc/profile.d/puppet-agent.sh
      echo 'export PATH="/usr/local/bin:/usr/local/sbin:${PATH}"' > /etc/profile.d/path.sh
      puppet module install puppet-r10k --environment production
      puppet cert generate puppet.local --dns_alt_names=puppet.local,puppet,puppetdb,puppetdb.local,prometheus,prometheus.local
      puppet resource service puppetserver enable=true ensure=running
      puppet apply -e 'include r10k'
      sed -i 's#remote:.*#remote: https://github.com/bastelfreak/osmc2019.git#' /etc/puppetlabs/r10k/r10k.yaml
      yum install --assumeyes git
      r10k deploy environment production --puppetfile --verbose --generate-types
      puppet agent -t --server prometheus
      puppet agent -t --server prometheus
    SHELL
  end
  config.vm.define "centosclient" do |centos|
    centos.vm.box = "centos/7"                                # base image we use
    centos.vm.hostname = "centosclient"                       # hostname that's configured within the VM
    centos.vm.network "private_network", ip: "192.168.33.11"
    centos.vm.provider "virtualbox" do |v|
      v.name = "centosclient"                                 # Name that's displayed within the VirtualBox UI
      v.memory = 2028                                         # Ram in MB
      v.cpus = 2                                              # Cores
    end
    centos.vm.provision "shell", inline: <<-SHELL
      yum install --assumeyes https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
      yum install --assumeyes puppet
      source /etc/profile.d/puppet-agent.sh
      echo 'export PATH="/usr/local/bin:/usr/local/sbin:${PATH}"' > /etc/profile.d/path.sh
      puppet agent -t --environment production --server prometheus
      puppet agent -t --environment production --server prometheus
    SHELL
  end
  config.vm.define "archclient" do |arch|
    arch.vm.box = "archlinux/archlinux"                        # base image we use
    arch.vm.hostname = "archclient"                            # hostname that's configured within the VM
    arch.vm.network "private_network", ip: "192.168.33.12"
    arch.vm.provider "virtualbox" do |v|
      v.name = "archclient"                                   # Name that's displayed within the VirtualBox UI
      v.memory = 2028                                         # Ram in MB
      v.cpus = 2                                              # Cores
    end
  end
end

# https://www.vagrantup.com/docs/virtualbox/configuration.html
# https://github.com/hashicorp/vagrant/wiki/Available-Vagrant-Plugins
# https://app.vagrantup.com/archlinux/boxes/archlinux
# https://www.vagrantup.com/docs/vagrantfile/vagrant_settings.html
