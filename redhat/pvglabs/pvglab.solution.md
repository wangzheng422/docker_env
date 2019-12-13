```bash

# on base host
cd /data
virt-install --name="ocp4-aHelper" --vcpus=2 --ram=4096 \
--disk path=/data/kvm/ocp4-aHelper.qcow2,bus=virtio,size=230 \
--os-variant centos7.0 --network network=openshift4,model=virtio \
--boot menu=on --location /data/rhel-server-7.6-x86_64-dvd.iso \
--initrd-inject helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" 

virt-viewer --domain-name ocp4-aHelper
virsh start ocp4-aHelper
virsh list --all

# in helper node
# ssh root@192.168.7.11
cat << EOF >>  /etc/hosts
192.168.7.1 yum.redhat.ren
EOF

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.redhat.ren/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist




```