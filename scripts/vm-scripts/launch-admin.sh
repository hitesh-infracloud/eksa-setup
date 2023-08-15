#!/bin/bash
# launch-admin-vm.sh

EKSA_ADMIN_IP='192.168.10.50/24'
EKSA_ADMIN_VM_LOCAL_PORT_FWD='5022'
EKSA_ADMIN_VM_CPUS='2'
EKSA_ADMIN_VM_MEM='16384'


VM_DIR='/root/eksa/vms'
NETWORK_CONFIG_FILE="${VM_DIR}/network_config"
EKSA_ADMIN_IP_ONLY=`echo ${EKSA_ADMIN_IP}| awk -F'/' '{print $1}'`

EKSA_NET=$(grep 'NetworkCidr' ${NETWORK_CONFIG_FILE}  | awk -F':' '{print $2}')
GATEWAY=$(grep 'NetworkGateway' ${NETWORK_CONFIG_FILE}   | awk -F':' '{print $2}')


generate_mac() {
  hex_chars="0123456789ABCDEF"
  mac=""
  
  for i in {1..6}; do
    mac+=${hex_chars:$((RANDOM % 16)):1}
    mac+=${hex_chars:$((RANDOM % 16)):1}
    
    if [ $i -lt 6 ]; then
      mac+=":"
    fi
  done
  
  echo "$mac"
}

generate_ip() {
  network="192.168.10"
  octet=$((RANDOM % 256))
  
  # Generate a random octet that is not 1 or 50
  while [ $octet -eq 1 ] || [ $octet -eq 50 ]; do
    octet=$((RANDOM % 256))
  done
  
  echo "$network.$octet"
}

exit_out() {
    echo ${1} && echo && exit -1
}


EKSA_ADMIN_MAC=$(generate_mac)
EKSA_ADMIN_MAC_CONCISE=`echo $EKSA_ADMIN_MAC | sed -e 's/://g'`
EKSA_ADMIN_VM_NAME="eksa-admin-vm"
EKSA_ADMIN_DIR="${VM_DIR}/gw/${EKSA_ADMIN_VM_NAME}"


echo -e "[+] Launching vm ${EKSA_ADMIN_VM_NAME} with IP ${EKSA_ADMIN_IP}"
[ -d ${EKSA_ADMIN_DIR} ] && exit_out "Detected an error...${EKSA_ADMIN_DIR} exists. Exiting"

echo -e "\t[+] Creating and switching to directory ${EKSA_ADMIN_DIR}"
mkdir -p ${EKSA_ADMIN_DIR} && cd ${EKSA_ADMIN_DIR}
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Generating netplan file 01-netcfg.yaml to bring vm interface up on NAT network 'eksa-net'"
echo -e "network:\n  version: 2\n  ethernets:\n    eth0:\n      addresses:\n        - ${EKSA_ADMIN_IP}\n      nameservers:\n        addresses: [8.8.8.8]\n      routes:\n        - to: default\n          via: ${GATEWAY}\n\n" > 01-netcfg.yaml
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Generating ssh key to be embedded in authorized_keys"
echo "n" | ssh-keygen -q -f ./vm-sshkey -t rsa -b 2048 -N ''
echo
echo -e "\t[+] Populate Vagrantfile for ${EKSA_ADMIN_VM_NAME} vm"
echo -e "Vagrant.configure(2) do |config|\n  config.vm.box = 'bento/ubuntu-20.04'\n  config.vm.network :forwarded_port, guest: 22, host: 2322, id: \"ssh\"\n  config.vm.hostname = '${EKSA_ADMIN_VM_NAME}'\n  config.vm.box_check_update = false\n  config.disksize.size = '100GB'\n  config.vm.boot_timeout = 300\n  config.persistent_storage.enabled = true\n  config.persistent_storage.location = \"virtualdrive.vdi\"\n  config.persistent_storage.size = 102400\n  config.persistent_storage.diskdevice = '/dev/sdc'\n  config.persistent_storage.partition = false\n  config.persistent_storage.use_lvm = false\n  config.vm.provider 'virtualbox' do |vb|\n    vb.cpus = ${EKSA_ADMIN_VM_CPUS}\n    vb.memory = ${EKSA_ADMIN_VM_MEM}\n    vb.name = '${EKSA_ADMIN_VM_NAME}'\n    vb.customize ['modifyvm', :id, '--macaddress1', '${EKSA_ADMIN_MAC_CONCISE}']\n  end\n config.vm.provision :shell, path: SOURCE_SCRIPTS_DIR + "/configure-admin.sh", args: []
 end\n\n" > ./Vagrantfile
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Running vagrant up for ${EKSA_ADMIN_VM_NAME} vm"
vagrant up
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Waiting for /vagrant filesystem to be availaible in ${EKSA_ADMIN_VM_NAME} vm \n"
vagrant ssh -c "ls /vagrant/" | grep -q netcfg
while [ $? -ne 0 ]; do sleep 1; vagrant ssh -c "ls /vagrant/" | grep -q netcfg; done

echo -e "\t[+] Setting up ${EKSA_ADMIN_VM_NAME} vm's netplan to switch to NAT network 'eksa-net'"
vagrant ssh -c "sudo cp -p /vagrant/01-netcfg.yaml /etc/netplan/01-netcfg.yaml; cat /etc/netplan/01-netcfg.yaml"

echo -e "\t[+] Setting up ${EKSA_ADMIN_VM_NAME} vm's ssh key based auth "
sleep 40
vagrant ssh -c "cat /vagrant/vm-sshkey.pub | sudo tee -a /root/.ssh/authorized_keys; cat /vagrant/vm-sshkey.pub >> /home/vagrant/.ssh/authorized_keys"
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Powering off ${EKSA_ADMIN_VM_NAME} vm"
sleep 10
VBoxManage controlvm ${EKSA_ADMIN_VM_NAME} poweroff
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Modify ${EKSA_ADMIN_VM_NAME} vm adapter definition to be on NAT network 'eksa-net'"
sleep 10
VBoxManage modifyvm ${EKSA_ADMIN_VM_NAME} --nic1 'natnetwork' --nat-network1 'eksa-net'
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Starting up ${EKSA_ADMIN_VM_NAME} vm"
sleep 10
VBoxManage startvm ${EKSA_ADMIN_VM_NAME} --type headless
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "Host ${EKSA_ADMIN_VM_NAME}\n    Hostname 127.0.0.1\n    StrictHostKeyChecking no\n    IdentityFile ${EKSA_ADMIN_DIR}/vm-sshkey\n    User vagrant\n    Port ${EKSA_ADMIN_VM_LOCAL_PORT_FWD} \n\n" | sudo tee -a /root/.ssh/config

echo -e "\t[+] Port forward local port ${EKSA_ADMIN_VM_LOCAL_PORT_FWD} to be able to ssh to ${EKSA_ADMIN_VM_NAME} vm's port 22"
VBoxManage natnetwork modify --netname eksa-net --port-forward-4 "ssh-to-${EKSA_ADMIN_VM_NAME}:tcp:[]:${EKSA_ADMIN_VM_LOCAL_PORT_FWD}:[${EKSA_ADMIN_IP_ONLY}]:22"
[ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

echo -e "\t[+] Please wait for ${EKSA_ADMIN_VM_NAME} vm to come up and then run ssh ${EKSA_ADMIN_VM_NAME}"

exit 0 