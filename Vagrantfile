Vagrant.configure("2") do |config|

  config.vm.define "admin" do |admin|
    admin.vm.box = "generic/ubuntu2204"
    admin.vm.hostname = "admin"
    admin.vm.provider "virtualbox" do |vb|
      vb.name = "admin"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ['modifyvm', :id, '--macaddress1', '0800277D1CFA']
    end
    # Assign NATNETWORK named eksa-net
    admin.vm.network "private_network", virtualbox__intnet: "eksa-net"
  end

  config.vm.define "machine1" do |machine1|
    machine1.vm.box = "jtyr/pxe"
    machine1.vm.hostname = "machine1"
    machine1.vm.provider "virtualbox" do |vb|
      vb.name = "machine1"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ['modifyvm', :id, '--macaddress1', '0800277D1CFB']
      vb.customize ["modifyvm", :id, "--nicbootprio1", "3"]
    end
    # Assign NATNETWORK named eksa-net
    machine1.vm.network "private_network", virtualbox__intnet: "eksa-net"

    machine1.vm.provision "shell", inline: "echo '#!ipxe\nexit' > /tmp/ipxe_script; VBoxManage modifyvm machine1 --nattftpfile1 /tmp/ipxe_script"
  end

  config.vm.define "machine2" do |machine2|
    machine2.vm.box = "jtyr/pxe"
    machine2.vm.hostname = "machine2"
    machine2.vm.provider "virtualbox" do |vb|
      vb.name = "machine2"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ['modifyvm', :id, '--macaddress1', '0800277D1CFC']
      vb.customize ["modifyvm", :id, "--nicbootprio1", "3"]
    end
    # Assign NATNETWORK named eksa-net
    machine2.vm.network "private_network", virtualbox__intnet: "eksa-net"

    machine2.vm.provision "shell", inline: "echo '#!ipxe\nexit' > /tmp/ipxe_script; VBoxManage modifyvm machine2 --nattftpfile1 /tmp/ipxe_script"
  end

end
