#!/bin/bash
# launch-cluster-vms.sh

CLUSTER_NAME="eksa-cluster"
NUM_CP_NODES="1"
NUM_DP_NODES="1"

CP_NODE_VM_CPUS='2'
CP_NODE_VM_MEM='16384'
DP_NODE_VM_CPUS='2'
DP_NODE_VM_MEM='16384'

#Variables
VM_DIR='/root/eksa/vms'
NETWORK_CONFIG_FILE="${VM_DIR}/network_config"
EKSA_NET=$(grep 'NetworkCidr' ${NETWORK_CONFIG_FILE}  | awk -F':' '{print $2}')
GATEWAY=$(grep 'NetworkGateway' ${NETWORK_CONFIG_FILE}   | awk -F':' '{print $2}')
NAMESERVERS='8.8.8.8'
EKSA_NET_CIDR=`echo ${EKSA_NET}| awk -F'/' '{print $2}'`

HARDWARE_CSV_LOCATION="${VM_DIR}/${CLUSTER_NAME}/generated_hardware.csv"
CLUSTER_TINKERBELL_IP=""
CLUSTER_ENDPOINT_IP=""

calc_netmask() {
  local cidr="$1"

  if ! [[ "$cidr" =~ ^[0-9]{1,2}$ && "$cidr" -le 32 ]]; then
    echo "Invalid CIDR notation: $cidr" >&2
    return 1
  fi

  local mask=$((0xffffffff << (32 - cidr)))
  echo "$((mask >> 24 & 0xff)).$((mask >> 16 & 0xff)).$((mask >> 8 & 0xff)).$((mask & 0xff))"
}

NETMASK=$(calc_netmask ${EKSA_NET_CIDR})

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

# Generate and store unique IPs in variables
declare -a ips=()
while [ ${#ips[@]} -lt 4 ]; do
  new_ip=$(generate_ip)
  
  if ! [[ " ${ips[@]} " =~ " ${new_ip} " ]]; then
    ips+=("$new_ip")
  fi
done

CLUSTER_TINKERBELL_IP="${ips[0]}"
CLUSTER_ENDPOINT_IP="${ips[1]}"
CP_VM_IP="${ips[2]}"
DP_VM2_IP="${ips[3]}"

# Generate and store unique MACs in variables
declare -a macs=()
while [ ${#macs[@]} -lt 2 ]; do
  new_mac=$(generate_mac)
  
  if ! [[ " ${macs[@]} " =~ " ${new_mac} " ]]; then
    macs+=("$new_mac")
  fi
done

CP_VM_MAC="${macs[0]}"
DP_VM_MAC="${macs[1]}"

exit_out() {
    echo ${1} && echo && exit -1
}

launch-cp-node-vm() {

    CP_NODE_NAME=${1}
    CP_NODE_IP=${2}
    CP_NODE_MAC_ADDR=${3}
    CP_NODE_DIR="${VM_DIR}/${CLUSTER_NAME}/${CP_NODE_NAME}"
    CP_NODE_MAC_ADDR_CONCISE=`echo $CP_NODE_MAC_ADDR | sed -e 's/://g'`

    echo -e "[+] Launching cp-node-vm ${CP_NODE_NAME} with IP ${CP_NODE_IP} and MAC ${CP_NODE_MAC_ADDR}"
    [ -d ${CP_NODE_DIR} ] && exit_out "Detected an error...${CP_NODE_DIR} exists. Exiting"

    echo -e "\t[+] Creating and switching to directory ${CP_NODE_DIR}"
    mkdir -p ${CP_NODE_DIR} && cd ${CP_NODE_DIR}
    [ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

    echo -e "\t[+] Populate Vagrantfile for cp-node-vm ${CP_NODE_NAME}"
    echo -e  "Vagrant.configure(2) do |config|\n  config.vm.box = 'jtyr/pxe'\n  config.vm.box_check_update = false\n  config.disksize.size = '100GB'\n  config.vm.boot_timeout = 30\n  config.persistent_storage.enabled = true\n  config.persistent_storage.location = \"virtualdrive.vdi\"\n  config.persistent_storage.size = 102400\n  config.persistent_storage.diskdevice = '/dev/sdc'\n  config.persistent_storage.partition = false\n  config.persistent_storage.use_lvm = false\n  config.vm.provider 'virtualbox' do |vb|\n    vb.cpus = ${CP_NODE_VM_CPUS}\n    vb.memory = ${CP_NODE_VM_MEM}\n    vb.name = '${CP_NODE_NAME}'\n    vb.customize ['modifyvm', :id, '--nic1', 'natnetwork', '--nat-network1', 'eksa-net']\n    vb.customize ['modifyvm', :id, '--macaddress1', '${CP_NODE_MAC_ADDR_CONCISE}']\n    vb.customize ['modifyvm', :id, '--boot1', 'net']\n    vb.customize ['modifyvm', :id, '--boot2', 'disk']\n    vb.customize ['modifyvm', :id, '--ostype', 'Linux_64']    \n  end\nend\n\n"  > ./Vagrantfile
    [ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

    echo -e "\t[+] Running vagrant up for cp-node-vm ${CP_NODE_NAME}. IGNORE ERROR - Timed out while waiting for the machine to boot."
    vagrant up

    echo -e "\t[+] Powering off cp-node-vm ${CP_NODE_NAME}"
    VBoxManage controlvm ${CP_NODE_NAME} poweroff

    echo -e "\t[+] Injecting entry in ${HARDWARE_CSV_LOCATION}: ${CP_NODE_NAME},${CP_NODE_MAC_ADDR},${CP_NODE_IP},${NETMASK},${GATEWAY},${NAMESERVERS},type=cp,/dev/sda,,, "
    [ ! -f ${HARDWARE_CSV_LOCATION} ] && echo "hostname,mac,ip_address,netmask,gateway,nameservers,labels,disk,bmc_ip,bmc_username,bmc_password" > ${HARDWARE_CSV_LOCATION}
    echo "${CP_NODE_NAME},${CP_NODE_MAC_ADDR},${CP_NODE_IP},${NETMASK},${GATEWAY},${NAMESERVERS},type=cp,/dev/sda,,," >> ${HARDWARE_CSV_LOCATION}
}

launch-dp-node-vm() {

    DP_NODE_NAME=${1}
    DP_NODE_IP=${2}
    DP_NODE_MAC_ADDR=${3}
    DP_NODE_DIR="${VM_DIR}/${CLUSTER_NAME}/${DP_NODE_NAME}"
    DP_NODE_MAC_ADDR_CONCISE=`echo $DP_NODE_MAC_ADDR | sed -e 's/://g'`


    echo -e "[+] Launching dp-node-vm ${DP_NODE_NAME} with IP ${DP_NODE_IP} and MAC ${DP_NODE_MAC_ADDR}"
    [ -d ${DP_NODE_DIR} ] && exit_out "Detected an error...${DP_NODE_DIR} exists. Exiting"

    echo -e "\t[+] Creating and switching to directory ${DP_NODE_DIR}"
    mkdir -p ${DP_NODE_DIR} && cd ${DP_NODE_DIR}
    [ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

    echo -e "\t[+] Populate Vagrantfile for dp-node-vm ${DP_NODE_NAME}"
    echo -e  "Vagrant.configure(2) do |config|\n  config.vm.box = 'jtyr/pxe'\n  config.vm.box_check_update = false\n  config.disksize.size = '100GB'\n  config.vm.boot_timeout = 30\n  config.persistent_storage.enabled = true\n  config.persistent_storage.location = \"virtualdrive.vdi\"\n  config.persistent_storage.size = 102400\n  config.persistent_storage.diskdevice = '/dev/sdc'\n  config.persistent_storage.partition = false\n  config.persistent_storage.use_lvm = false\n  config.vm.provider 'virtualbox' do |vb|\n    vb.cpus = ${DP_NODE_VM_CPUS}\n    vb.memory = ${DP_NODE_VM_MEM}\n    vb.name = '${DP_NODE_NAME}'\n    vb.customize ['modifyvm', :id, '--nic1', 'natnetwork', '--nat-network1', 'eksa-net']\n    vb.customize ['modifyvm', :id, '--macaddress1', '${DP_NODE_MAC_ADDR_CONCISE}']\n    vb.customize ['modifyvm', :id, '--boot1', 'net']\n    vb.customize ['modifyvm', :id, '--boot2', 'disk']\n    vb.customize ['modifyvm', :id, '--ostype', 'Linux_64']    \n  end\nend\n\n"  > ./Vagrantfile
    [ $? -ne 0 ] && exit_out 'Detected an error...exiting!!'

    echo -e "\t[+] Running vagrant up for dp-node-vm ${DP_NODE_NAME}. IGNORE ERROR - Timed out while waiting for the machine to boot."
    vagrant up

    echo -e "\t[+] Powering off dp-node-vm ${CP_NODE_NAME}"
    VBoxManage controlvm ${DP_NODE_NAME} poweroff

    echo -e "\t[+] Injecting entry in ${HARDWARE_CSV_LOCATION}: ${DP_NODE_NAME},${DP_NODE_MAC_ADDR},${DP_NODE_IP},${NETMASK},${GATEWAY},${NAMESERVERS},type=dp,/dev/sda,,, "
    [ ! -f ${HARDWARE_CSV_LOCATION} ] && echo "hostname,mac,ip_address,netmask,gateway,nameservers,labels,disk,bmc_ip,bmc_username,bmc_password" > ${HARDWARE_CSV_LOCATION}
    echo "${DP_NODE_NAME},${DP_NODE_MAC_ADDR},${DP_NODE_IP},${NETMASK},${GATEWAY},${NAMESERVERS},type=dp,/dev/sda,,," >> ${HARDWARE_CSV_LOCATION}

}

CP_NODE_NAME="${CLUSTER_NAME}-cp"
DP_NODE_NAME="${CLUSTER_NAME}-dp"

launch-cp-node-vm ${CP_NODE_NAME} ${CP_VM_IP} ${CP_VM_MAC}
launch-dp-node-vm ${DP_NODE_NAME} ${DP_VM_IP} ${DP_VM_MAC}

echo 

CLUSTER_TINKERBELL_IP=$(head -1 ${CLUSTER_TINKERBELL_IP_FILE}| awk '{print $1}')
echo -e "[+] TinkerbellIP ${CLUSTER_TINKERBELL_IP} for cluster ${CLUSTER_NAME}"

CLUSTER_ENDPOINT_IP=$(head -1 ${CLUSTER_ENDPOINT_IP_FILE}| awk '{print $1}')
echo -e "[+] EndpointIP ${CLUSTER_ENDPOINT_IP} for cluster ${CLUSTER_NAME}"

echo -e "[+] Generated Hardware.csv"
cat ${HARDWARE_CSV_LOCATION}
echo 