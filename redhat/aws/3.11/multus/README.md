#

https://github.com/openshift/multus-cni

https://github.com/dougbtv/openshift-ansible/tree/multus-developer-preview/playbooks/openshift-multinetwork

```bash

kubectl apply -f ocp-multus-daemonset.yml

yum -y install pciutils
lspci | grep -i ethernet

cat << EOF > /etc/modprobe.d/sriov.conf
options ixgbe max_vfs=8,8
EOF


cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec: 
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.111.0/24",
        "rangeStart": "192.168.111.200",
        "rangeEnd": "192.168.111.216",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.111.1"
      }
    }'
EOF

cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf-2
spec: 
  config: '{
  "cniVersion": "0.3.0",
  "type": "macvlan",
  "name": "macvlan-conf-2",
  "master": "eth1",
  "mode": "bridge",
  "ipam": {
      "type": "host-local",
      "ranges": [
          [ {
               "subnet": "192.168.10.0/24",
               "rangeStart": "192.168.10.20",
               "rangeEnd": "192.168.10.0.50"
          } ]
      ]
  }
}'
EOF


cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf-2
spec:
  containers:
  - name: samplepod
    command: ["ping","localhost"]
    image: aws-registry.redhat.ren/nicolaka/netshoot
EOF



```