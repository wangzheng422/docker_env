# GPU 在 openshift 3.11 kvm 部署环境中的验证

验证结论是，用kvm部署openshift 3.11，支持nvidia GPU passthrough。

整个安装过程的重点，是宿主机的kernel启动参数intel_iommu=on， 以及gpu vm的domain配置。其他配置过程，和正常集群安装没有区别。

```bash
# on kvm host
cat << EOF >>  /etc/hosts
172.29.122.232 registry.crmi.cn
172.29.122.232 yum.crmi.cn
EOF

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.crmi.cn/data
enabled=1
gpgcheck=0

EOF

yum repolist

hostnamectl set-hostname kvm.crmi.cn
nmcli connection modify enp134s0f0 ipv4.dns 172.29.122.151
nmcli connection reload
nmcli connection up enp134s0f0

yum -y install byobu htop bzip2
yum -y update

yum -y install dnsmasq

cat  > /etc/dnsmasq.d/openshift-cluster.conf << EOF
local=/crmi.cn/
address=/.apps.crmi.cn/192.168.8.12
address=/master.crmi.cn/192.168.8.11
address=/lb.crmi.cn/192.168.8.12
address=/infra.crmi.cn/192.168.8.12
address=/registry.crmi.cn/172.29.122.232
address=/node1.crmi.cn/192.168.8.13
address=/node2.crmi.cn/192.168.8.14
address=/node3.crmi.cn/192.168.8.15
EOF

systemctl restart dnsmasq.service && systemctl enable dnsmasq.service && systemctl status dnsmasq.service

firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

systemctl restart dnsmasq

cp /etc/crts/crmi.cn.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

mkdir -p /data/kvm
cd /data
mkdir -p /data/kvm/master
tar zxf rhel-gpu.tar.bz2 --directory /data/kvm/master
mkdir -p /data/kvm/infra
cp /data/kvm/master/rhel-gpu.qcow2  /data/kvm/infra/
mkdir -p /data/kvm/node1
cp /data/kvm/master/rhel-gpu.qcow2  /data/kvm/node1/
mkdir -p /data/kvm/node2
cp /data/kvm/master/rhel-gpu.qcow2  /data/kvm/node2/
mkdir -p /data/kvm/node3
cp /data/kvm/master/rhel-gpu.qcow2  /data/kvm/node3/

cat << EOF > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
gnome-session &
EOF
chmod +x ~/.vnc/xstartup

vncserver :1 -geometry 1280x800

firewall-cmd --permanent --add-port=6001/tcp
firewall-cmd --permanent --add-port=5901/tcp
firewall-cmd --reload

cd /data

cat << EOF >>  /data/virt-net.xml
<network>
  <name>openshift</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='openshift' stp='on' delay='0'/>
  <domain name='openshift'/>
  <ip address='192.168.8.1' netmask='255.255.255.0'>
  </ip>
</network>
EOF

virsh net-define --file virt-net.xml
virsh net-autostart openshift
virsh net-start openshift

virt-install --name=ocp-master --vcpus=8 --ram=32768 \
--disk path=/data/kvm/master/rhel-gpu.qcow2,bus=virtio \
--os-variant rhel7.6 --network network=openshift,model=virtio \
--boot menu=on

# on master vm
hostnamectl set-hostname master.crmi.cn
nmcli connection modify eth0 ipv4.addresses 192.168.8.11/24
nmcli connection modify eth0 ipv4.gateway 192.168.8.1
nmcli connection modify eth0 ipv4.dns 172.29.122.151
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd

systemctl disable libvirtd.service

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.crmi.cn/data
enabled=1
gpgcheck=0

EOF

yum repolist

yum -y update

rm -f /var/lib/NetworkManager/secret_key

poweroff

# on kvm host
virt-install --name=ocp-infra --vcpus=8 --ram=32768 \
--disk path=/data/kvm/infra/rhel-gpu.qcow2,bus=virtio \
--os-variant rhel7.6 --network network=openshift,model=virtio \
--boot menu=on

# on infra vm
hostnamectl set-hostname infra.crmi.cn
nmcli connection modify eth0 ipv4.addresses 192.168.8.12/24
nmcli connection modify eth0 ipv4.gateway 192.168.8.1
nmcli connection modify eth0 ipv4.dns 172.29.122.151
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl disable libvirtd.service

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.crmi.cn/data
enabled=1
gpgcheck=0

EOF

yum repolist

yum -y update

rm -f /var/lib/NetworkManager/secret_key

poweroff

# on kvm host
virt-install --name=ocp-node1 --vcpus=8 --ram=32768 \
--disk path=/data/kvm/node1/rhel-gpu.qcow2,bus=virtio \
--disk path=/data/kvm/node1/gfs.qcow2,bus=virtio,size=200 \
--os-variant rhel7.6 --network network=openshift,model=virtio \
--boot menu=on

# on node1 vm
hostnamectl set-hostname node1.crmi.cn
nmcli connection modify eth0 ipv4.addresses 192.168.8.13/24
nmcli connection modify eth0 ipv4.gateway 192.168.8.1
nmcli connection modify eth0 ipv4.dns 172.29.122.151
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl disable libvirtd.service

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.crmi.cn/data
enabled=1
gpgcheck=0

EOF

yum repolist

yum -y update

rm -f /var/lib/NetworkManager/secret_key

poweroff

# on kvm host
virt-install --name=ocp-node2 --vcpus=8 --ram=32768 \
--disk path=/data/kvm/node2/rhel-gpu.qcow2,bus=virtio \
--disk path=/data/kvm/node2/gfs.qcow2,bus=virtio,size=200 \
--os-variant rhel7.6 --network network=openshift,model=virtio \
--boot menu=on

# on node2 vm
hostnamectl set-hostname node2.crmi.cn
nmcli connection modify eth0 ipv4.addresses 192.168.8.14/24
nmcli connection modify eth0 ipv4.gateway 192.168.8.1
nmcli connection modify eth0 ipv4.dns 172.29.122.151
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl disable libvirtd.service

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.crmi.cn/data
enabled=1
gpgcheck=0

EOF

yum repolist

yum -y update

rm -f /var/lib/NetworkManager/secret_key

poweroff

# on kvm host
virt-install --name=ocp-node3 --vcpus=8 --ram=32768 \
--disk path=/data/kvm/node3/rhel-gpu.qcow2,bus=virtio \
--disk path=/data/kvm/node3/gfs.qcow2,bus=virtio,size=200 \
--os-variant rhel7.6 --network network=openshift,model=virtio \
--boot menu=on

# on node3 vm
hostnamectl set-hostname node3.crmi.cn
nmcli connection modify eth0 ipv4.addresses 192.168.8.15/24
nmcli connection modify eth0 ipv4.gateway 192.168.8.1
nmcli connection modify eth0 ipv4.dns 172.29.122.151
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl disable libvirtd.service

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.crmi.cn/data
enabled=1
gpgcheck=0

EOF

yum repolist

yum -y update

rm -f /var/lib/NetworkManager/secret_key

poweroff

# on kvm host for gpu

##  gpu driver
yum -y install kernel-devel-`uname -r`
yum -y install xorg-x11-drv-nvidia xorg-x11-drv-nvidia-devel nvidia-modprobe nvidia-driver-NVML nvidia-driver-cuda
modprobe -r nouveau
nvidia-modprobe && nvidia-modprobe -u
nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0 | sed -e 's/ /-/g'

lspci -Dnn | grep -i nvidia
# 0000:18:00.0 3D controller [0302]: NVIDIA Corporation Device [10de:1eb8] (rev a1)

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-device-gpu
# edit or add the GRUB_CMDLINX_LINUX line to the /etc/sysconfig/grub
# intel_iommu=on iommu=pt pci-stub.ids=10de:1eb8
grub2-mkconfig -o /etc/grub2-efi.cfg

virsh nodedev-dumpxml pci_0000_18_00_0

virsh nodedev-detach pci_0000_18_00_0

cd /data

cat <<EOF > /data/gpu.xml
<hostdev mode='subsystem' type='pci' managed='yes'>
 <driver name='vfio'/>
 <source>
  <address domain='0x0000' bus='0x18' slot='0x00' function='0x0'/>
 </source>
</hostdev>
EOF

virsh list --all
#  Id    Name                           State
# ----------------------------------------------------
#  -     ocp-infra                      shut off
#  -     ocp-master                     shut off
#  -     ocp-node1                      shut off
#  -     ocp-node2                      shut off
#  -     ocp-node3                      shut off

virsh attach-device ocp-node1 /data/gpu.xml --persistent

# on node1 vm
yum -y install kernel-devel-`uname -r`
yum -y install xorg-x11-drv-nvidia xorg-x11-drv-nvidia-devel nvidia-modprobe nvidia-driver-NVML nvidia-driver-cuda
modprobe -r nouveau
nvidia-modprobe && nvidia-modprobe -u
nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0 | sed -e 's/ /-/g'

lspci -Dnn | grep -i nvidia

# on kvm host

yum -y install ansible-2.6.18-1.el7ae

cd /data/
cat << EOF > /data/ansible_host
[cmcc]
192.168.8.11
192.168.8.12
192.168.8.13
192.168.8.14
192.168.8.15

EOF

ansible -i ansible_host cmcc -u root -m timezone -a "name=Asia/Shanghai"
ansible -i ansible_host cmcc -u root -m copy -a "src=/etc/crts/crmi.cn.crt dest=/etc/pki/ca-trust/source/anchors/"
ansible -i ansible_host cmcc -u root -m command -a "update-ca-trust extract"

yum -y install openshift-ansible

for i in master infra node1 node2 node3; do ssh-copy-id $i.crmi.cn; done;

ansible-playbook -v -i hosts-3.11.117.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -v -i hosts-3.11.117.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -i hosts-3.11.117.yaml /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml

ansible -i ansible_host cmcc -u root -m shell -a "vgs | tail -1 | awk '{print $1}'"

# gpu test
# on node1 vm
yum -y install nvidia-container-runtime-hook

semodule -i nvidia-container.pp
nvidia-container-cli -k list | restorecon -v -f -
restorecon -Rv /dev
restorecon -Rv /var/lib/kubelet

docker run  --rm --user 1000:1000 --security-opt=no-new-privileges --cap-drop=ALL --security-opt label=type:nvidia_container_t     registry.crmi.cn:5021/mirrorgooglecontainers/cuda-vector-add:v0.1

# on master vm
oc project kube-system
oc label node node1.crmi.cn openshift.com/gpu-accelerator=true
oc create -f nvidia-device-plugin.yml
oc describe node node1.crmi.cn | grep -A 10 "Allocatable:"

oc new-project nvidia
oc project nvidia
oc create -f cuda-vector-add.yaml
oc logs pod/cuda-vector-add
# [Vector addition of 50000 elements]
# Copy input data from the host memory to the CUDA device
# CUDA kernel launch with 196 blocks of 256 threads
# Copy output data from the CUDA device to the host memory
# Test PASSED
# Done
```
