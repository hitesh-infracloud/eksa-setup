## Setup infra & cluster

### Setup infra

```bash
cd eksa-setup/scripts/aws-tf

terraform init

terraform plan

terraform apply --auto-approve
```

**Note**
The pem certificate needs to be at `~/.aws/key-pairs/eksa-admin.pem`. 
Else change the script to point to the directory where it is available.


### Generate cluster config

```bash
export CLUSTER_NAME=mgmt

eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > eksa-mgmt-cluster.yaml
```

### Create hardware.csv file

```bash
# fetch hardware/vm contents from EC2 instance
ssh into EC2 instance: `ssh -i <pem-cert-path> ubuntu@<ec2-instance-ip>`
hardware details should be at: `cat /home/ubuntu/vm-scripts/logs/launch-vms.log`

touch hardware.csv

vi hardware.csv

# populate content as per generated speciifcations in below format
hostname,mac,ip_address,netmask,gateway,nameservers,labels,disk,bmc_ip,bmc_username,bmc_password
eksabmhp1-cp-n-1,08:00:27:99:5B:B7,192.168.10.179,255.255.255.0,192.168.10.1,8.8.8.8,type=cp,/dev/sda,,,
eksabmhp1-dp-n-1,08:00:27:AC:C9:77,192.168.10.31,255.255.255.0,192.168.10.1,8.8.8.8,type=cp,/dev/sda,,,
```

### Start cluster provisioning

```bash
eksctl anywhere create cluster --hardware-csv hardware.csv -f eksa-mgmt-cluster.yaml
```

### Monitor & Debug

```bash
# to view local kind cluster containers
docker ps -a

# to stream boots conatiner logs
docker logs -f boots

# to view machine status in local kind cluster
KUBECONFIG=mgmt/generated/mgmt.kind.kubeconfig kubectl get machine -n eksa-system

# to view workflow status in local kind cluster
KUBECONFIG=mgmt/generated/mgmt.kind.kubeconfig kubectl get workflow -n eksa-system
```
