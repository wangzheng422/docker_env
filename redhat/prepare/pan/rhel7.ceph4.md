# CEPH4 in kvm on rhel8, host rhel7

```bash

subscription-manager --proxy=127.0.0.1:6666 register --username **** --password ********

subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com
subscription-manager --proxy=127.0.0.1:6666 refresh

subscription-manager --proxy=127.0.0.1:6666 repos --disable="*"
subscription-manager --proxy=127.0.0.1:6666 repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-supplementary-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-server-ansible-2.9-rpms" \
    #


yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -y install yum-plugin-fastestmirror

yum group list
yum groupinstall 'Server with GUI'

yum -y install wget yum-utils htop byobu ethtool tigervnc-server tigervnc

yum -y update

# after reboot
lvremove -f centos/root centos/home centos/swap

pvcreate /dev/nvme0n1
vgcreate nvme /dev/nvme0n1

lvremove -f nvme/cephlv
lvcreate -y -L 50G -n cephlv nvme
lvremove -f nvme/cephdata01lv
lvcreate -y -l 33%FREE -n cephdata01lv nvme
lvremove -f nvme/cephdata02lv
lvcreate -y -l 33%FREE -n cephdata02lv nvme
lvremove -f nvme/cephdata03lv
lvcreate -y -l 34%FREE -n cephdata03lv nvme

yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable --now libvirtd

vncpasswd

cat << EOF > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
vncconfig &
gnome-session &
EOF
chmod +x ~/.vnc/xstartup

vncserver :1 -geometry 1280x800
# 如果你想停掉vnc server，这么做
vncserver -kill :1

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=em1
DEVICE=em1
ONBOOT=yes
# IPADDR=117.177.241.18
# PREFIX=24
# GATEWAY=117.177.241.1
IPV6_PRIVACY=no
# DNS1=117.177.241.16
BRIDGE=br0
EOF

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-br0 
TYPE=Bridge
BOOTPROTO=static
IPADDR=172.21.6.101
GATEWAY=172.21.6.254
DNS1=172.21.1.1
ONBOOT=yes
DEFROUTE=yes
NAME=br0
DEVICE=br0
PREFIX=24
EOF

systemctl restart network

cat << EOF >  /data/virt-net.xml
<network>
  <name>br0</name>
  <forward mode='bridge'>
    <bridge name='br0'/>
  </forward>
</network>
EOF
virsh net-define --file /data/virt-net.xml
virsh net-autostart br0
virsh net-start br0

grubby --update-kernel=/boot/vmlinuz-$(uname -r) --args="intel_iommu=on"
grubby --update-kernel=/boot/vmlinuz-$(uname -r) --remove-args="intel_iommu=on"

nmcli connection add type bridge con-name br-ceph ifname br-ceph ip4 172.21.7.11/24
nmcli con modify br-ceph bridge.stp no
nmcli con up br-ceph
nmcli con add type ethernet ifname p1p1 master br-ceph
nmcli con add type ethernet ifname p1p2 master br-ceph
nmcli con add type ethernet ifname p3p1 master br-ceph
nmcli con add type ethernet ifname p3p2 master br-ceph

virt-install --name=ceph --vcpus=16 --ram=32768 \
--disk path=/dev/nvme/cephlv,device=disk,bus=virtio,format=raw \
--disk path=/dev/nvme/cephdata01lv,device=disk,bus=virtio,format=raw \
--disk path=/dev/nvme/cephdata02lv,device=disk,bus=virtio,format=raw \
--disk path=/dev/nvme/cephdata03lv,device=disk,bus=virtio,format=raw \
--network bridge=br0,model=virtio \
--network bridge=br-ceph,model=virtio \
--os-variant centos8 \
--boot menu=on --location /data/rhel-8.3-x86_64-dvd.iso \
--initrd-inject rhel-ks-ceph.cfg --extra-args "inst.ks=file://data/rhel-ks-ceph.cfg" 

#########################################################
## ceph node
export PROXY="172.21.6.101:6666"

subscription-manager --proxy=$PROXY register --auto-attach --username **** --password ********

subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com

# subscription-manager --proxy=$PROXY repos --list > list
# cat list | grep 'Repo ID' | grep -v source | grep -v debug

subscription-manager --proxy=$PROXY repos --disable="*"
subscription-manager --proxy=$PROXY repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhel-8-for-x86_64-supplementary-rpms" \
    --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms \
    --enable=ansible-2.8-for-rhel-8-x86_64-rpms \
    --enable=rhceph-4-mon-for-rhel-8-x86_64-rpms \
    --enable=rhceph-4-osd-for-rhel-8-x86_64-rpms \
    --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms
    #

yum update -y

systemctl enable --now firewalld
# systemctl start firewalld
systemctl status firewalld

firewall-cmd --zone=public --add-port=6789/tcp
firewall-cmd --zone=public --add-port=6789/tcp --permanent
firewall-cmd --zone=public --add-port=6800-7300/tcp
firewall-cmd --zone=public --add-port=6800-7300/tcp --permanent
firewall-cmd --zone=public --add-port=6800-7300/tcp
firewall-cmd --zone=public --add-port=6800-7300/tcp --permanent
firewall-cmd --zone=public --add-port=6800-7300/tcp
firewall-cmd --zone=public --add-port=6800-7300/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp
firewall-cmd --zone=public --add-port=443/tcp --permanent
# firewall-cmd --zone=public --add-port=9090/tcp
# firewall-cmd --zone=public --add-port=9090/tcp --permanent

nmcli con add type ethernet ifname ens11 con-name ens11
nmcli con modify ens11 ipv4.method manual ipv4.addresses 172.21.7.12/24
nmcli con modify ens11 connection.autoconnect yes
nmcli con reload
nmcli con up ens11

ssh-keygen

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd

ssh-copy-id root@lab101-ceph

yum install -y ceph-ansible podman

cd /root
curl -o rhceph-4.1-rhel-8-x86_64.iso "https://access.cdn.redhat.com/content/origin/files/sha256/b7/b7130b75f727073f99064f9df1df7e6c591a72853bbc792b951f96c76423ac66/rhceph-4.1-rhel-8-x86_64.iso?user=a768b217cf6ae8041b67586bb4dd5c77&_auth_=1605062405_acf4417e5810855f38ef3d8dfddf14a6"

cd /usr/share/ceph-ansible
/bin/cp -f  group_vars/all.yml.sample group_vars/all.yml
/bin/cp -f  group_vars/osds.yml.sample group_vars/osds.yml
/bin/cp -f  site-docker.yml.sample site-docker.yml
/bin/cp -f  site.yml.sample site.yml
/bin/cp -f  group_vars/rgws.yml.sample group_vars/rgws.yml
/bin/cp -f  group_vars/mdss.yml.sample group_vars/mdss.yml

# remember to set the env
# https://access.redhat.com/RegistryAuthentication
# REGISTRY_USER_NAME=
# REGISTRY_TOKEN=

cat << EOF > ./group_vars/all.yml
fetch_directory: ~/ceph-ansible-keys
monitor_interface: ens11 
public_network: 172.21.7.0/24
# ceph_docker_image: rhceph/rhceph-4-rhel8
# ceph_docker_image_tag: "latest"
# containerized_deployment: true
ceph_docker_registry: registry.redhat.io
ceph_docker_registry_auth: true
ceph_docker_registry_username: ${REGISTRY_USER_NAME}
ceph_docker_registry_password: ${REGISTRY_TOKEN}
ceph_origin: repository
ceph_repository: rhcs
# ceph_repository_type: cdn
ceph_repository_type: iso
ceph_rhcs_iso_path: /root/rhceph-4.1-rhel-8-x86_64.iso
ceph_rhcs_version: 4
bootstrap_dirs_owner: "167"
bootstrap_dirs_group: "167"
dashboard_admin_user: admin
dashboard_admin_password: Redhat!23
node_exporter_container_image: registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.1
grafana_admin_user: admin
grafana_admin_password: Redhat!23
grafana_container_image: registry.redhat.io/rhceph/rhceph-4-dashboard-rhel8
prometheus_container_image: registry.redhat.io/openshift4/ose-prometheus:4.1
alertmanager_container_image: registry.redhat.io/openshift4/ose-prometheus-alertmanager:4.1
radosgw_interface: eth1
radosgw_address_block: 172.21.7.0/24
radosgw_civetweb_port: 8080
radosgw_civetweb_num_threads: 512
ceph_conf_overrides:
  global:
    osd_pool_default_size: 1
    osd_pool_default_min_size: 1
    osd_pool_default_pg_num: 32
    osd_pool_default_pgp_num: 32
  osd:
   osd_scrub_begin_hour: 22
   osd_scrub_end_hour: 7

EOF

cat << EOF > ./group_vars/osds.yml
devices:
  - /dev/vdb
EOF

cat << EOF > ./hosts
[grafana-server]
lab101-ceph
[mons]
lab101-ceph
[osds]
lab101-ceph
[mgrs]
lab101-ceph

EOF

sed -i "s/#copy_admin_key: false/copy_admin_key: true/" ./group_vars/rgws.yml

cd /usr/share/ceph-ansible

mkdir -p ~/ceph-ansible-keys
ansible all -m ping -i hosts

ansible-playbook -vv site.yml -i hosts

#  You can access your dashboard web UI at http://lab101-ceph:8443/ as an 'admin' user with 'Redhat!23' password

cd /root
ceph osd getcrushmap -o crushmap
crushtool -d crushmap -o crushmap.txt
sed -i 's/step chooseleaf firstn 0 type host/step chooseleaf firstn 0 type osd/' crushmap.txt
grep 'step chooseleaf' crushmap.txt
crushtool -c crushmap.txt -o crushmap-new
ceph osd setcrushmap -i crushmap-new
cd /usr/share/ceph-ansible

# test the result
ceph health detail
ceph osd pool create test 8
ceph osd pool set test pg_num 128
ceph osd pool set test pgp_num 128
ceph osd pool application enable test rbd
ceph -s
ceph osd tree
ceph osd pool ls
ceph pg dump
cat << EOF > hello-world.txt
wangzheng
EOF
rados --pool test put hello-world hello-world.txt
rados --pool test get hello-world fetch.txt
cat fetch.txt

# continue to install
cat << EOF >> ./hosts
[rgws]
lab101-ceph
[mdss]
lab101-ceph

EOF

ansible-playbook -vv site.yml --limit mdss -i hosts

ansible-playbook -vv site.yml --limit rgws -i hosts

# change mon param for S3
# 416 (InvalidRange)
# https://www.cnblogs.com/flytor/p/11380026.html
# https://www.cnblogs.com/fuhai0815/p/12144214.html
# https://access.redhat.com/solutions/3328431
# https://themeanti.me/technology/2018/03/14/ceph-pgs.html
# add config line
vi /etc/ceph/ceph.conf
# [global]
# mon_max_pg_per_osd = 1000
# osd_max_pg_per_osd_hard_ratio = 100

systemctl restart ceph-mgr@lab101-ceph.service
systemctl restart ceph-mon@lab101-ceph.service

# ceph tell mon.* injectargs '--mon_max_pg_per_osd=1000'

ceph --admin-daemon /var/run/ceph/ceph-mon.`hostname -s`.asok config show | grep mon_max_pg_per_osd

# ceph --admin-daemon /var/run/ceph/ceph-mgr.`hostname -s`.asok config set mon_max_pg_per_osd 1000

ceph osd lspools
ceph osd dump | grep 'replicated size'



```