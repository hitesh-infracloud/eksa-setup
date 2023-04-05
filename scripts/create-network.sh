#!/bin/bash

# Create NAT network
VBoxManage natnetwork add --netname eksa-net --network "192.168.10.0/24" --dhcp off

# Configure NAT network
VBoxManage natnetwork modify --netname eksa-net --ipv6 off --port-forward-4 "ssh:tcp:[]:2222:[192.168.10.4]:22"
