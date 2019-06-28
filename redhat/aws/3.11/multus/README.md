#

https://github.com/openshift/multus-cni

https://github.com/dougbtv/openshift-ansible/tree/multus-developer-preview/playbooks/openshift-multinetwork

```bash

yum -y install pciutils
lspci | grep -i ethernet

cat << EOF > /etc/modprobe.d/sriov.conf
options ixgbe max_vfs=8,8
EOF

ansible -i inventory aws -m copy -a "src=./cni/macvlan dest=/opt/cni/bin"
ansible -i inventory aws -m file -a "name=/opt/cni/bin/macvlan mode=+x"

ansible -i inventory aws -m copy -a "src=./cni/flannel dest=/opt/cni/bin"
ansible -i inventory aws -m file -a "name=/opt/cni/bin/flannel mode=+x"

ansible -i inventory aws -m copy -a "src=./cni/dhcp dest=/opt/cni/bin"
ansible -i inventory aws -m file -a "name=/opt/cni/bin/dhcp mode=+x"

oc project openshift-sdn
oc create serviceaccount dhcp
oc adm policy add-scc-to-user anyuid -z dhcp
oc adm policy add-scc-to-user privileged -z dhcp

kubectl apply -f ocp-multus-daemonset.yml
kubectl apply -f dhcp.yml

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
        "rangeEnd": "192.168.111.216"
      }
    }'
EOF

cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: dhcp-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "net0",
      "mode": "bridge",
      "ipam": {
        "type": "dhcp"
      }
    }'
EOF

kubectl api-resources --verbs=list -o name | xargs -n 1 kubectl get -o name

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
        "type": "dhcp"
      }
    }'
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  nodeSelector:
    kubernetes.io/hostname: aws-n1.redhat.ren
  containers:
  - name: samplepod
    command: ["ping","localhost"]
    image: aws-registry.redhat.ren/nicolaka/netshoot
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  containers:
  - name: samplepod
    command: ["ping","localhost"]
    image: aws-registry.redhat.ren/nicolaka/netshoot
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod2
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  nodeSelector:
    kubernetes.io/hostname: aws-n1.redhat.ren
  containers:
  - name: samplepod
    command: ["ping","localhost"]
    image: aws-registry.redhat.ren/nicolaka/netshoot
EOF



```