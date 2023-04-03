### Generate cluster config

```bash
export CLUSTER_NAME=mgmt

eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > eksa-mgmt-cluster.yaml
```

### Create hardware.csv file

```bash
touch hardware.csv

vi hardware.csv

# add below content as per your speciifcations
hostname,mac,ip_address,netmask,gateway,nameservers,labels,disk,bmc_ip,bmc_username,bmc_password
eksabmhp1-cp-n-1,08:00:27:7D:1C:FB,192.168.56.94,255.255.255.0,192.168.56.1,8.8.8.8,type=cp,/dev/sda,,,
eksabmhp1-dp-n-1,08:00:27:7D:1C:FC,192.168.56.33,255.255.255.0,192.168.56.1,8.8.8.8,type=dp,/dev/sda,,,
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
