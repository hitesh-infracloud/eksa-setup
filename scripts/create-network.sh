#!/bin/bash

VM_DIR='/root/eksa/vms'
NETWORK_CONFIG_FILE="${VM_DIR}/network_config"


exit_out() {
    echo ${1} && echo && exit -1
}

flush-iptables() {
    echo -e "[+] Flushing local iptables"
    iptables -F; iptables -t nat -F; netfilter-persistent save  > /dev/null 2>&1
}

EKSA_NET='192.168.10.0/24'
GATEWAY='192.168.10.1'


echo -e "[+] Creating natnetwork eksa-net with cidr ${EKSA_NET} and gateway ${GATEWAY}"
VBoxManage natnetwork add --netname eksa-net --network "192.168.10.0/24" --dhcp off
[ $? -ne 0 ] && exit_out "Detected an error while creating natnetwork eksa-net...exiting!!"

VBoxManage natnetwork start --netname eksa-net

echo -e "[+] Populating network config ${NETWORK_CONFIG_FILE}"
echo -e "NetworkCidr:$EKSA_NET\nNetworkGateway:${GATEWAY}" > ${NETWORK_CONFIG_FILE}
cat ${NETWORK_CONFIG_FILE}

exit 0
