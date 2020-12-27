```bash

podman start local-registry

podman start nexus

podman start nexus-image

systemctl start vncserver@:1

# setup ftp data root
mount --bind /data/dnf /var/ftp/dnf
chcon -R -t public_content_t  /var/ftp/dnf

ps -ef | grep vbmcd | awk '{print $2}' | xargs kill
/bin/rm -f /root/.vbmc/master.pid
/root/.local/bin/vbmcd

/root/.local/bin/sushy-emulator -i 0.0.0.0 --ssl-certificate /etc/crts/redhat.ren.crt --ssl-key /etc/crts/redhat.ren.key

virsh start ocp4-aHelper
virsh start ocp4-master0 
virsh start ocp4-master1 
virsh start ocp4-master2 
virsh start ocp4-worker0 
virsh start ocp4-worker1 
virsh start ocp4-worker2

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


virt-install --name=ocp4-worker0 --vcpus=8 --ram=65536 \
--cpu=host-model \
--disk path=/dev/nvme/worker0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-worker0.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-worker0.xml

virt-install --name=ocp4-worker1 --vcpus=4 --ram=32768 \
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


```

## on 102
```bash

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

virt-install --name=ocp4-master0 --vcpus=4 --ram=16384 \
--cpu=host-model \
--disk path=/dev/nvme/master0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-master0.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-master0.xml

virt-install --name=ocp4-master1 --vcpus=4 --ram=16384 \
--cpu=host-model \
--disk path=/dev/nvme/master1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-master1.xml
virsh define --file ${KVM_DIRECTORY}/ocp4-master1.xml

virt-install --name=ocp4-master2 --vcpus=4 --ram=16384 \
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

ssh root@192.168.7.1 'cat /data/kvm/mac.list' >>  /data/kvm/mac.list

scp /data/kvm/mac.list root@192.168.7.11:/data/install/mac.list
```

## on helper

```bash
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


```