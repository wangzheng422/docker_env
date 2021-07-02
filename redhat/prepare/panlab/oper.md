# daily operation

## 101

```bash
virsh start ocp4-aHelper

# on helper
podman start local-registry
podman start nexus-image

# on 101
virsh start ocp4-master0 
virsh start ocp4-master1 

# on 103
# virsh start ocp4-worker1

# on 104
virsh start ocp4-master2 
virsh start ocp4-worker0

vncserver :1 -geometry 1280x800

# shutdown
nodes=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')
for node in ${nodes[@]}
do
    echo "==== Shut down $node ===="
    ssh core@$node sudo poweroff
done

nodes="172.21.6.101 172.21.6.104"
for node in $nodes
do
    echo "==== show $node ===="
    ssh root@$node virsh list
done


```

## normal boot up

```bash
# on 105
podman start local-registry

podman start nexus

podman start nexus-image

podman start gitea

systemctl start vncserver@:1

# setup ftp data root
mount --bind /data/dnf /var/ftp/dnf
chcon -R -t public_content_t  /var/ftp/dnf

ps -ef | grep vbmcd | awk '{print $2}' | xargs kill
/bin/rm -f /root/.vbmc/master.pid
/root/.local/bin/vbmcd

/root/.local/bin/sushy-emulator -i 0.0.0.0 --ssl-certificate /etc/crts/redhat.ren.crt --ssl-key /etc/crts/redhat.ren.key

virsh start ocp4-aHelper
sleep 60
virsh start ocp4-master0 
# sleep 10
virsh start ocp4-master1 
# sleep 10
virsh start ocp4-master2 
sleep 120
virsh start ocp4-worker0 
# virsh start ocp4-worker1 
# virsh start ocp4-worker2

# on 102
systemctl start vncserver@:1

/root/.local/bin/sushy-emulator -i 0.0.0.0 --ssl-certificate /data/install/redhat.ren.crt --ssl-key /data/install/redhat.ren.key

virsh start ocp4-master0 
virsh start ocp4-master1 
virsh start ocp4-master2 

# on helper, 192.168.7.11
systemctl start vncserver@:1

# proxy
cat << EOF > /data/ocp4/proxy.yaml
apiVersion: config.openshift.io/v1
kind: Proxy
metadata:
  name: cluster
spec:
  httpProxy: 'http://172.21.6.105:18801'
  httpsProxy: 'http://172.21.6.105:18801' 
  noProxy: '.redhat.ren,192.168.'
  readinessEndpoints:
  - http://www.google.com 
  - https://www.google.com
EOF
oc apply -f /data/ocp4/proxy.yaml

oc edit proxy/cluster

# shutdown
nodes=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')
for node in ${nodes[@]}
do
    echo "==== Shut down $node ===="
    ssh -i ~/.ssh/helper_rsa core@$node sudo shutdown -h 1
done


```

## on 105
```bash

# virsh destroy ocp4-bootstrap
virsh destroy ocp4-worker0 
virsh destroy ocp4-worker1 
virsh destroy ocp4-worker2
# virsh undefine ocp4-bootstrap
virsh undefine ocp4-worker0 --nvram
virsh undefine ocp4-worker1 --nvram
virsh undefine ocp4-worker2 --nvram

export KVM_DIRECTORY=/data/kvm
mkdir -p ${KVM_DIRECTORY}
cd ${KVM_DIRECTORY}

remove_lv() {
    var_vg=$1
    var_lv=$2
    lvremove -f $var_vg/$var_lv
}

create_lv() {
    var_vg=$1
    var_lv=$2
    lvcreate -y -L 120G -n $var_lv $var_vg
    wipefs --all --force /dev/$var_vg/$var_lv
}

remove_lv nvme worker0lv
remove_lv nvme worker1lv
remove_lv rhel worker2lv

create_lv nvme worker0lv
create_lv nvme worker1lv
create_lv rhel worker2lv


virt-install --name=ocp4-worker0 --vcpus=10 --ram=71680 \
--cpu=host-model \
--disk path=/dev/nvme/worker0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-worker0.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-worker0.xml

virt-install --name=ocp4-worker1 --vcpus=10 --ram=71680 \
--cpu=host-model \
--disk path=/dev/nvme/worker1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-worker1.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-worker1.xml

virt-install --name=ocp4-worker2 --vcpus=2 --ram=8192 \
--cpu=host-model \
--disk path=/dev/rhel/worker2lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-worker2.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-worker2.xml

cd /data/kvm/
for i in worker{0..2}
do
  echo -ne "${i}\t" ; 
  virsh dumpxml ocp4-${i} | grep "mac address" | cut -d\' -f2 | tr '\n' '\t'
  echo 
done > mac.list
cat /data/kvm/mac.list

/root/.local/bin/sushy-emulator -i 0.0.0.0 --ssl-certificate /etc/crts/redhat.ren.crt --ssl-key /etc/crts/redhat.ren.key

```

## on 102
```bash
scp /etc/crts/redhat.ren.crt root@192.168.7.2:/data/install/
scp /etc/crts/redhat.ren.key root@192.168.7.2:/data/install/

export KVM_DIRECTORY=/data/kvm
mkdir -p ${KVM_DIRECTORY}

cat << 'EOF' > /data/kvm/bridge.sh
#!/usr/bin/env bash

PUB_CONN='eno1'
PUB_IP='172.21.6.102/24'
PUB_GW='172.21.6.254'
PUB_DNS='172.21.1.1'

nmcli con down "$PUB_CONN"
nmcli con delete "$PUB_CONN"
nmcli con down baremetal
nmcli con delete baremetal
# RHEL 8.1 appends the word "System" in front of the connection,delete in case it exists
nmcli con down "System $PUB_CONN"
nmcli con delete "System $PUB_CONN"
nmcli connection add ifname baremetal type bridge con-name baremetal ipv4.method 'manual' \
    ipv4.address "$PUB_IP" \
    ipv4.gateway "$PUB_GW" \
    ipv4.dns "$PUB_DNS"
    
nmcli con add type bridge-slave ifname "$PUB_CONN" master baremetal
nmcli con down "$PUB_CONN";pkill dhclient;dhclient baremetal
nmcli con up baremetal
EOF

nmcli con mod baremetal +ipv4.address '192.168.7.2/24'
nmcli networking off; nmcli networking on


# virsh destroy ocp4-bootstrap
virsh destroy ocp4-master0 
virsh destroy ocp4-master1 
virsh destroy ocp4-master2 
# virsh undefine ocp4-bootstrap
virsh undefine ocp4-master0 --nvram
virsh undefine ocp4-master1 --nvram
virsh undefine ocp4-master2 --nvram

export KVM_DIRECTORY=/data/kvm
mkdir -p ${KVM_DIRECTORY}
cd ${KVM_DIRECTORY}

remove_lv() {
    var_vg=$1
    var_lv=$2
    lvremove -f $var_vg/$var_lv
}

create_lv() {
    var_vg=$1
    var_lv=$2
    lvcreate -y -L 120G -n $var_lv $var_vg
    wipefs --all --force /dev/$var_vg/$var_lv
}

remove_lv nvme master0lv
remove_lv nvme master1lv
remove_lv nvme master2lv

# create_lv rhel bootstraplv
create_lv nvme master0lv
create_lv nvme master1lv
create_lv nvme master2lv

virt-install --name=ocp4-master0 --vcpus=12 --ram=18432 \
--cpu=host-model \
--disk path=/dev/nvme/master0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-master0.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-master0.xml

virt-install --name=ocp4-master1 --vcpus=12 --ram=18432 \
--cpu=host-model \
--disk path=/dev/nvme/master1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-master1.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-master1.xml

virt-install --name=ocp4-master2 --vcpus=12 --ram=18432 \
--cpu=host-model \
--disk path=/dev/nvme/master2lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-master2.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-master2.xml

cd /data/kvm/
for i in master{0..2}
do
  echo -ne "${i}\t" ; 
  virsh dumpxml ocp4-${i} | grep "mac address" | cut -d\' -f2 | tr '\n' '\t'
  echo 
done > mac.list
cat /data/kvm/mac.list

/root/.local/bin/sushy-emulator -i 0.0.0.0 --ssl-certificate /data/install/redhat.ren.crt --ssl-key /data/install/redhat.ren.key

```

## on helper

```bash

ssh root@192.168.7.1 'cat /data/kvm/mac.list' > /data/install/mac.list

ssh root@192.168.7.2 'cat /data/kvm/mac.list' >> /data/install/mac.list

cat /data/install/mac.list


mkdir -p /data/ocp4/
cd /data/ocp4/
cat << 'EOF' > redfish.sh
#!/usr/bin/env bash

curl -k -s https://192.168.7.1:8000/redfish/v1/Systems/ | jq -r '.Members[]."@odata.id"' >  list

while read -r line; do
    curl -k -s https://192.168.7.1:8000/$line | jq -j '.Id, " ", .Name, "\n" '
done < list

curl -k -s https://192.168.7.2:8000/redfish/v1/Systems/ | jq -r '.Members[]."@odata.id"' >  list

while read -r line; do
    curl -k -s https://192.168.7.2:8000/$line | jq -j '.Id, " ", .Name, "\n" '
done < list

EOF
bash redfish.sh > /data/install/vm.list
cat /data/install/vm.list


cat << EOF > /data/ocp4/ocp4-upi-helpernode-master/vars-dhcp.rhel8.yaml
---
ssh_gen_key: true
staticips: false
bm_ipi: true
firewalld: false
dns_forward: false
iso:
  iso_dl_url: "file:///data/ocp4/rhcos-live.x86_64.iso"
  my_iso: "rhcos-live.iso"
helper:
  name: "helper"
  ipaddr: "192.168.7.11"
  networkifacename: "enp1s0"
  gateway: "192.168.7.1"
  netmask: "255.255.255.0"
dns:
  domain: "redhat.ren"
  clusterid: "ocp4"
  forwarder1: "192.168.7.1"
  forwarder2: "192.168.7.1"
  api_vip: "192.168.7.100"
  ingress_vip: "192.168.7.101"
dhcp:
  router: "192.168.7.1"
  bcast: "192.168.7.255"
  netmask: "255.255.255.0"
  poolstart: "192.168.7.70"
  poolend: "192.168.7.90"
  ipid: "192.168.7.0"
  netmaskid: "255.255.255.0"
bootstrap:
  name: "bootstrap"
  ipaddr: "192.168.7.12"
  interface: "enp1s0"
  install_drive: "vda"
  macaddr: "52:54:00:7e:f8:f7"
masters:
  - name: "master-0"
    ipaddr: "192.168.7.13"
    interface: "enp1s0"
    install_drive: "vda"
    macaddr: "$(cat /data/install/mac.list | grep master0 | awk '{print $2}')"
  - name: "master-1"
    ipaddr: "192.168.7.14"
    interface: "enp1s0"
    install_drive: "vda"    
    macaddr: "$(cat /data/install/mac.list | grep master1 | awk '{print $2}')"
  - name: "master-2"
    ipaddr: "192.168.7.15"
    interface: "enp1s0"
    install_drive: "vda"   
    macaddr: "$(cat /data/install/mac.list | grep master2 | awk '{print $2}')"
workers:
  - name: "worker-0"
    ipaddr: "192.168.7.16"
    interface: "enp1s0"
    install_drive: "vda"
    macaddr: "$(cat /data/install/mac.list | grep worker0 | awk '{print $2}')"
  - name: "worker-1"
    ipaddr: "192.168.7.17"
    interface: "enp1s0"
    install_drive: "vda"
    macaddr: "$(cat /data/install/mac.list | grep worker1 | awk '{print $2}')"
  - name: "worker-2"
    ipaddr: "192.168.7.18"
    interface: "enp1s0"
    install_drive: "vda"
    macaddr: "$(cat /data/install/mac.list | grep worker2 | awk '{print $2}')"
others:
  - name: "registry"
    ipaddr: "192.168.7.1"
    macaddr: "52:54:00:7e:f8:f7"
  - name: "yum"
    ipaddr: "192.168.7.1"
    macaddr: "52:54:00:7e:f8:f7"
  - name: "quay"
    ipaddr: "192.168.7.1"
    macaddr: "52:54:00:7e:f8:f7"
  - name: "nexus"
    ipaddr: "192.168.7.1"
    macaddr: "52:54:00:7e:f8:f7"
  - name: "git"
    ipaddr: "192.168.7.1"
    macaddr: "52:54:00:7e:f8:f7"
otherdomains:
  - domain: "rhv.redhat.ren"
    hosts:
    - name: "manager"
      ipaddr: "192.168.7.71"
    - name: "rhv01"
      ipaddr: "192.168.7.72"
  - domain: "cmri-edge.redhat.ren"
    hosts:
    - name: "*"
      ipaddr: "192.168.7.71"
    - name: "*.apps"
      ipaddr: "192.168.7.72"
force_ocp_download: false
remove_old_config_files: false
ocp_client: "file:///data/ocp4/4.6.9/openshift-client-linux-4.6.9.tar.gz"
ocp_installer: "file:///data/ocp4/4.6.9/openshift-install-linux-4.6.9.tar.gz"
ppc64le: false
arch: 'x86_64'
chronyconfig:
  enabled: true
  content:
    - server: "192.168.7.1"
      options: iburst
setup_registry:
  deploy: false
  registry_image: docker.io/library/registry:2
  local_repo: "ocp4/openshift4"
  product_repo: "openshift-release-dev"
  release_name: "ocp-release"
  release_tag: "4.6.1-x86_64"
registry_server: "registry.ocp4.redhat.ren:5443"
EOF

cd /data/ocp4/ocp4-upi-helpernode-master
ansible-playbook -e @vars-dhcp.rhel8.yaml -e '{ staticips: false, bm_ipi: true }'  tasks/main.yml


# 定制ignition
cd /data/install

# vi install-config.yaml 
cat << EOF > /data/install/install-config.yaml 
apiVersion: v1
baseDomain: redhat.ren
platform:
  baremetal:
    apiVIP: 192.168.7.100
    ingressVIP: 192.168.7.101
    bootstrapProvisioningIP: 192.168.7.102
    provisioningHostIP: 192.168.7.103
    provisioningNetwork: "Disabled"
    bootstrapOSImage: http://192.168.7.11:8080/install/rhcos-qemu.x86_64.qcow2.gz?sha256=$(zcat /var/www/html/install/rhcos-qemu.x86_64.qcow2.gz | sha256sum | awk '{print $1}')
    clusterOSImage: http://192.168.7.11:8080/install/rhcos-openstack.x86_64.qcow2.gz?sha256=$(sha256sum /var/www/html/install/rhcos-openstack.x86_64.qcow2.gz | awk '{print $1}')
    hosts:
      - name: master-0
        role: master
        bmc:
          address: redfish-virtualmedia://192.168.7.2:8000/redfish/v1/Systems/$(cat vm.list | grep master0 | awk '{print $1}')
          username: admin
          password: password
          disableCertificateVerification: True
        bootMACAddress: $(cat mac.list | grep master0 | awk '{print $2}')
        rootDeviceHints:
          deviceName: "/dev/vda"
      - name: master-1
        role: master
        bmc:
          address: redfish-virtualmedia://192.168.7.2:8000/redfish/v1/Systems/$(cat vm.list | grep master1 | awk '{print $1}')
          username: admin
          password: password
          disableCertificateVerification: True
        bootMACAddress: $(cat mac.list | grep master1 | awk '{print $2}')
        rootDeviceHints:
          deviceName: "/dev/vda"
      - name: master-2
        role: master
        bmc:
          address: redfish-virtualmedia://192.168.7.2:8000/redfish/v1/Systems/$(cat vm.list | grep master2 | awk '{print $1}')
          username: admin
          password: password
          disableCertificateVerification: True
        bootMACAddress: $(cat mac.list | grep master2 | awk '{print $2}')
        rootDeviceHints:
          deviceName: "/dev/vda"
      - name: worker-0
        role: worker
        bmc:
          address: redfish-virtualmedia://192.168.7.1:8000/redfish/v1/Systems/$(cat vm.list | grep worker0 | awk '{print $1}')
          username: admin
          password: password
          disableCertificateVerification: True
        bootMACAddress: $(cat mac.list | grep worker0 | awk '{print $2}')
        rootDeviceHints:
          deviceName: "/dev/vda"
      - name: worker-1
        role: worker
        bmc:
          address: redfish-virtualmedia://192.168.7.1:8000/redfish/v1/Systems/$(cat vm.list | grep worker1 | awk '{print $1}')
          username: admin
          password: password
          disableCertificateVerification: True
        bootMACAddress: $(cat mac.list | grep worker1 | awk '{print $2}')
        rootDeviceHints:
          deviceName: "/dev/vda"
metadata:
  name: ocp4
networking:
  clusterNetworks:
  - cidr: 10.254.0.0/16
    hostPrefix: 24
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
  machineCIDR: 192.168.7.0/24
compute:
- name: worker
  replicas: 2
controlPlane:
  name: master
  replicas: 3
  platform:
    baremetal: {}
pullSecret: '$( cat /data/pull-secret.json )'
sshKey: |
$( cat /root/.ssh/helper_rsa.pub | sed 's/^/   /g' )
additionalTrustBundle: |
$( cat /data/install/redhat.ren.ca.crt | sed 's/^/   /g' )
imageContentSources:
- mirrors:
  - registry.ocp4.redhat.ren:5443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - registry.ocp4.redhat.ren:5443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

```

## go to 102
```bash

# GO back to host
mkdir -p /data/install
cd /data/install
scp root@192.168.7.11:/data/install/install-config.yaml /data/install/

cd /data/install
for i in $(sudo virsh list --all | tail -n +3 | grep bootstrap | awk {'print $2'});
do
  sudo virsh destroy $i;
  sudo virsh undefine $i;
  sudo virsh vol-delete $i --pool default;
  sudo virsh vol-delete $i.ign --pool default;
  virsh pool-destroy $i
  virsh pool-delete $i
  virsh pool-undefine $i
done
/bin/rm -rf .openshift_install.log .openshift_install_state.json terraform* auth tls 
/data/ocp4/4.6.9/openshift-baremetal-install --dir /data/install/ --log-level debug create cluster

# INFO Install complete!
# INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/data/install/auth/kubeconfig'
# INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp4.redhat.ren
# INFO Login to the console with user: "kubeadmin", and password: "R3eL2-bLJQ8-A2U3b-2Twm6"



```