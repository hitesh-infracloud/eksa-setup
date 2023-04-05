
SOURCE_SCRIPTS_DIR = "scripts/"
DEST_SCRIPTS_DIR = "/tmp/scripts/"

Vagrant.configure("2") do |config|

  config.vm.define "eksa-hp-admin-1" do |admin|
    admin.vm.box = "generic/ubuntu2004"
    admin.ssh.forward_agent = true
    admin.ssh.username = 'vagrant'
    admin.ssh.password = 'vagrant'
    admin.vm.synced_folder SOURCE_SCRIPTS_DIR, DEST_SCRIPTS_DIR
    admin.vm.hostname = "eksa-hp-admin-1"
    admin.vm.provider "virtualbox" do |vb, override|
      vb.name = "eksa-hp-admin-1"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ['modifyvm', :id, '--macaddress1', '0800277D1CFA']
      override.vm.synced_folder SOURCE_SCRIPTS_DIR, DEST_SCRIPTS_DIR
    end

    # Assign NATNETWORK named eksa-net
    admin.vm.network "private_network", ip: "192.168.10.4", netmask: "255.255.255.0", virtualbox__intnet: "eksa-net"

    # Execute configure-admin.sh script
    admin.vm.provision :shell, path: SOURCE_SCRIPTS_DIR + "/configure-admin.sh", args: []
  end

  config.vm.define "eksabmhp1-cp-n-1" do |machine1|
    machine1.vm.box = "jtyr/pxe"
    machine1.vm.hostname = "eksabmhp1-cp-n-1"
    machine1.vm.provider "virtualbox" do |vb|
      vb.name = "eksabmhp1-cp-n-1"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ['modifyvm', :id, '--macaddress1', '080027995BB7']
      vb.customize ["modifyvm", :id, "--nicbootprio1", "3"]
    end
    # Assign NATNETWORK named eksa-net
    machine1.vm.network "private_network", virtualbox__intnet: "eksa-net"

    machine1.vm.provision "shell", inline: "echo '#!ipxe\nexit' > /tmp/ipxe_script; VBoxManage modifyvm eksabmhp1-cp-n-1 --nattftpfile1 /tmp/ipxe_script"
  end

  config.vm.define "eksabmhp1-dp-n-1" do |machine2|
    machine2.vm.box = "jtyr/pxe"
    machine2.vm.hostname = "eksabmhp1-dp-n-1"
    machine2.vm.provider "virtualbox" do |vb|
      vb.name = "eksabmhp1-dp-n-1"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ['modifyvm', :id, '--macaddress1', '080027ACC977']
      vb.customize ["modifyvm", :id, "--nicbootprio1", "3"]
    end
    # Assign NATNETWORK named eksa-net
    machine2.vm.network "private_network", virtualbox__intnet: "eksa-net"

    machine2.vm.provision "shell", inline: "echo '#!ipxe\nexit' > /tmp/ipxe_script; VBoxManage modifyvm eksabmhp1-dp-n-1 --nattftpfile1 /tmp/ipxe_script"
  end

end
