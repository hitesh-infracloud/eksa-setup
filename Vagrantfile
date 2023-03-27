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
end
