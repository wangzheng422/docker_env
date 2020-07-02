# cmri labs install

## jumpbox

```bash

yum install icedtea-web

# to crmi
rsync -e ssh --info=progress2 -P --delete -arz  /root/data root@172.29.159.3:/home/wzh/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz  /data/ocp4/ root@172.29.159.3:/home/wzh/ocp4/

rsync -e ssh --info=progress2 -P --delete -arz  /data/registry/  root@172.29.159.3:/home/wzh/registry/

rsync -e ssh --info=progress2 -P --delete -arz  /data/is.samples/ root@172.29.159.3:/home/wzh/is.samples/

tar -cvf - is.samples/ | pigz -c > is.samples.tgz
tar -cvf - ocp4/ | pigz -c > ocp4.tgz
tar -cvf - registry/ | pigz -c > registry.tgz
tar -cvf - rhel-data/ | pigz -c > rhel-data.tgz


```
## try with ovs
https://pinrojas.com/2017/05/03/how-to-use-virt-install-to-connect-at-openvswitch-bridges/

https://blog.csdn.net/wuliangtianzu/article/details/81870551

https://stackoverflow.com/questions/30622680/kvm-ovs-bridged-network-how-to-configure

https://stackoverflow.com/questions/31566658/setup-private-networking-between-two-hosts-and-two-vms-with-libvirt-openvswitc

follow this to setup ovs network:
https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.4/4.4.ovs.md

### redhat-01

```bash
# on redhat-01
timedatectl set-timezone Asia/Shanghai

pvcreate /dev/sdb
vgcreate datavg /dev/sdb

lvcreate -L 1T -n datalv datavg
mkfs.ext4 /dev/datavg/datalv
mount /dev/datavg/datalv /data

# rclone config
# rclone lsd jumpbox:
# rclone sync jumpbox:/home/wzh/  /data/down/ -P -L --transfers 10

pigz -dc registry.tgz | tar xf -
pigz -dc is.samples.tgz | tar xf -
pigz -dc rhel-data.tgz | tar xf -
pigz -dc ocp4.tgz | tar xf -

yum -y install vsftpd
systemctl enable --now vsftpd

mkdir -p /var/ftp/data
mount --bind /data/down/rhel-data/data /var/ftp/data
chcon -R -t public_content_t  /var/ftp/data

mkdir /etc/crts/ && cd /etc/crts
openssl req \
   -newkey rsa:2048 -nodes -keyout redhat.ren.key \
   -x509 -days 3650 -out redhat.ren.crt -subj \
   "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.redhat.ren"

cp /etc/crts/redhat.ren.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

yum -y install podman docker-distribution pigz skopeo
# pigz -dc registry.tgz | tar xf -
cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /data/down/registry
    delete:
        enabled: true
http:
    addr: :5443
    tls:
       certificate: /etc/crts/redhat.ren.crt
       key: /etc/crts/redhat.ren.key
EOF

systemctl enable --now docker-distribution
systemctl restart docker-distribution

mkdir -p /data/kvm
cd /data/kvm

lvremove -f datavg/helperlv
lvcreate -y -L 430G -n helperlv datavg

wipefs --all --force /dev/datavg/helperlv

# 430G
virt-install --name="ocp4-aHelper" --vcpus=2 --ram=4096 \
--disk path=/dev/datavg/helperlv,device=disk,bus=virtio,format=raw \
--os-variant centos7.0 --network network:br-int,model=virtio \
--boot menu=on --location /data/kvm/rhel-server-7.8-x86_64-dvd.iso \
--initrd-inject /data/kvm/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" 

scp /etc/crts/* 192.168.7.11:/root/
scp /data/down/ocp4.tgz 192.168.7.11:/root/
scp /data/down/ocp4-upi-helpernode.zip 192.168.7.11:/root/ocp4


```

### redhat-02

```bash
# on redhat-02

lvcreate -L 1T -n datalv datavg
mkfs.ext4 /dev/datavg/datalv
mount /dev/datavg/datalv /data

mkdir -p /data/kvm
cd /data/kvm

lvremove -f datavg/helperlv
lvcreate -y -L 230G -n helperlv datavg

# 230G
virt-install --name="ocp4-aHelper" --vcpus=2 --ram=4096 \
--disk path=/dev/datavg/helperlv,device=disk,bus=virtio,format=raw \
--os-variant centos7.0 --network network:br-int,model=virtio \
--boot menu=on --location /data/kvm/rhel-server-7.8-x86_64-dvd.iso \
--initrd-inject /data/kvm/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" 



```

### helper

```bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://192.168.7.1/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y install ansible git unzip podman

# scp ocp4.tgz to /root
cd /root
tar zvxf ocp4.tgz
cd /root/ocp4

unzip ocp4-upi-helpernode-master.zip
# podman load -i fedora.tgz
podman load -i filetranspiler.tgz
# 根据现场环境，修改 ocp4-upi-helpernode-master/vars-static.yaml
cd ocp4-upi-helpernode-master
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml


# on helper node
cd /root/ocp4
mkdir -p /data
# export BUILDNUMBER=$(cat release.txt | grep 'Name:' | awk '{print $NF}')
export BUILDNUMBER=4.4.7
echo ${BUILDNUMBER}
# export BUILDNUMBER=4.2.4
export OCP_RELEASE=${BUILDNUMBER}
export LOCAL_REG='registry.redhat.ren:5443'
export LOCAL_REPO='ocp4/openshift4'
export UPSTREAM_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="/data/pull-secret.json"
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
export RELEASE_NAME="ocp-release"

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
EOF

cat << 'EOF' >> /etc/sysconfig/network-scripts/ifcfg-eth0
MTU=1450
EOF
systemctl restart network

cd /root/ocp4

vi install-config.yaml 

/bin/rm -rf *.ign .openshift_install_state.json auth bootstrap master0 master1 master2 worker0 worker1 worker2

# openshift-install create ignition-configs --dir=/root/ocp4
openshift-install create manifests --dir=/root/ocp4
# scp calico/manifests to manifests

# https://access.redhat.com/solutions/5092381
cat << 'EOF' > /root/ocp4/30-mtu.sh
#!/bin/sh
MTU=1450
INTERFACE=ens3

IFACE=$1
STATUS=$2
if [ "$IFACE" = "$INTERFACE" -a "$STATUS" = "up" ]; then
    ip link set "$IFACE" mtu $MTU
fi
EOF

cat /root/ocp4/30-mtu.sh | base64 -w0

cat << EOF > /root/ocp4/manifests/30-mtu.yaml
kind: MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
metadata:
  name: 99-worker-mtu
  creationTimestamp: 
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  osImageURL: ''
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - filesystem: root
        path: "/etc/NetworkManager/dispatcher.d/30-mtu"
        contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL3NoCk1UVT05MDAwCklOVEVSRkFDRT1lbnM0CgpJRkFDRT0kMQpTVEFUVVM9JDIKaWYgWyAiJElGQUNFIiA9ICIkSU5URVJGQUNFIiAtYSAiJFNUQVRVUyIgPSAidXAiIF07IHRoZW4KICAgIGlwIGxpbmsgc2V0ICIkSUZBQ0UiIG10dSAkTVRVCmZpCg==
          verification: {}
        mode: 0755
    systemd:
      units:
        - contents: |
            [Unit]
            Requires=systemd-udevd.target
            After=systemd-udevd.target
            Before=NetworkManager.service
            DefaultDependencies=no
            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/restorecon /etc/NetworkManager/dispatcher.d/30-mtu
            [Install]
            WantedBy=multi-user.target
          name: one-shot-mtu.service
          enabled: true
EOF

openshift-install create ignition-configs --dir=/root/ocp4


/bin/cp -f bootstrap.ign /var/www/html/ignition/bootstrap-static.ign
/bin/cp -f master.ign /var/www/html/ignition/master-0.ign
/bin/cp -f master.ign /var/www/html/ignition/master-1.ign
/bin/cp -f master.ign /var/www/html/ignition/master-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-2.ign

chmod 644 /var/www/html/ignition/*

```

### redhat-01

```bash


yum -y install genisoimage libguestfs-tools
systemctl enable --now libvirtd

export NGINX_DIRECTORY=/data/ocp4
export RHCOSVERSION=4.4.3
export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.x86_64.iso | awk '/Volume id/ { print $3 }')
TEMPDIR=$(mktemp -d)
echo $VOLID
echo $TEMPDIR

cd ${TEMPDIR}
# Extract the ISO content using guestfish (to avoid sudo mount)
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.x86_64.iso \
  -m /dev/sda tar-out / - | tar xvf -

# Helper function to modify the config files
modify_cfg(){
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    # Append the proper image and ignition urls
    sed -e '/coreos.inst=yes/s|$| coreos.inst.install_dev=vda coreos.inst.image_url='"${URL}"'\/install\/'"${BIOSMODE}"'.raw.gz coreos.inst.ignition_url='"${URL}"'\/ignition\/'"${NODE}"'.ign ip='"${IP}"'::'"${GATEWAY}"':'"${NETMASK}"':'"${FQDN}"':'"${NET_INTERFACE}"':none:'"1450"' nameserver='"${DNS}"'|' ${file} > $(pwd)/${NODE}_${file##*/}
    # Boot directly in the installation
    sed -i -e 's/default vesamenu.c32/default linux/g' -e 's/timeout 600/timeout 10/g' $(pwd)/${NODE}_${file##*/}
  done
}

URL="http://192.168.7.11:8080/"
GATEWAY="192.168.7.1"
NETMASK="255.255.255.0"
DNS="192.168.7.11"

# BOOTSTRAP
# TYPE="bootstrap"
NODE="bootstrap-static"
IP="192.168.7.12"
FQDN="bootstrap"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTERS
# TYPE="master"
# MASTER-0
NODE="master-0"
IP="192.168.7.13"
FQDN="master-0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-1
NODE="master-1"
IP="192.168.7.14"
FQDN="master-1"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-2
NODE="master-2"
IP="192.168.7.15"
FQDN="master-2"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# WORKERS
NODE="worker-0"
IP="192.168.7.16"
FQDN="worker-0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-1"
IP="192.168.7.17"
FQDN="worker-1"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-2"
IP="192.168.7.18"
FQDN="worker-2"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# Generate the images, one per node as the IP configuration is different...
# https://github.com/coreos/coreos-assembler/blob/master/src/cmd-buildextend-installer#L97-L103
for node in master-0 master-1 master-2 worker-0 worker-1 worker-2 bootstrap-static; do
  # Overwrite the grub.cfg and isolinux.cfg files for each node type
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    /bin/cp -f $(pwd)/${node}_${file##*/} ${file}
  done
  # As regular user!
  genisoimage -verbose -rock -J -joliet-long -volset ${VOLID} \
    -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -efi-boot images/efiboot.img -no-emul-boot \
    -o ${NGINX_DIRECTORY}/${node}.iso .
done

# Optionally, clean up
cd
rm -Rf ${TEMPDIR}

cd ${NGINX_DIRECTORY}

scp *.iso root@172.29.159.100:/data/ocp4/

create_lv() {
    var_name=$1
    lvremove -f datavg/$var_name
    lvcreate -y -L 120G -n $var_name datavg
    # wipefs --all --force /dev/datavg/$var_name
}

create_lv bootstraplv
create_lv master0lv
create_lv master1lv
create_lv master2lv
create_lv worker0lv

# finally, we can start install :)
# 你可以一口气把虚拟机都创建了，然后喝咖啡等着。
# 从这一步开始，到安装完毕，大概30分钟。
virt-install --name=ocp4-bootstrap --vcpus=4 --ram=8192 \
--disk path=/dev/datavg/bootstraplv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/bootstrap-static.iso   

# 想登录进coreos一探究竟？那么这么做
# ssh core@192.168.7.12 
# journalctl -b -f -u bootkube.service

virt-install --name=ocp4-master0 --vcpus=4 --ram=24576 \
--disk path=/dev/datavg/master0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-0.iso 

# ssh core@192.168.7.13

virt-install --name=ocp4-master1 --vcpus=4 --ram=24576 \
--disk path=/dev/datavg/master1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-1.iso 

virt-install --name=ocp4-master2 --vcpus=4 --ram=24576 \
--disk path=/dev/datavg/master2lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-2.iso 

virt-install --name=ocp4-worker0 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-0.iso 


for i in vnet0 vnet1 vnet2 vnet3 vnet4 vnet5; do
    ovs-vsctl set int $i mtu_request=1450
done 

```

### redhat-02

```bash
export NGINX_DIRECTORY=/data/ocp4

create_lv() {
    var_name=$1
    lvremove -f datavg/$var_name
    lvcreate -y -L 120G -n $var_name datavg
    wipefs --all --force /dev/datavg/$var_name
}

create_lv worker1lv
create_lv worker2lv

virt-install --name=ocp4-worker1 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-1.iso 

ovs-vsctl set int vnet0 mtu_request=1450
ovs-vsctl set int br-int mtu_request=1450

virt-install --name=ocp4-worker2 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-2.iso 


```

## try with rhv

### redhat-01

```bash
mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://172.29.159.3/wzh/rhel-data/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

systemctl disable firewalld.service
systemctl stop firewalld.service

yum -y install byobu htop glances dstat bmon

hostnamectl set-hostname rhv01.rhv.redhat.ren


# setup time server
yum install -y chrony

/bin/cp -f /etc/chrony.conf /etc/chrony.conf.bak

cat << EOF > /etc/chrony.conf
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 172.29.159.0/24
local stratum 10
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking

# https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.3/html-single/installing_red_hat_virtualization_as_a_self-hosted_engine_using_the_cockpit_web_interface/index

# nfs server, no need, later will use ansible to provide
# https://qizhanming.com/blog/2018/08/08/how-to-install-nfs-on-centos-7
# yum -y install nfs-utils 

# mkdir -p /exports/data

# groupadd kvm -g 36
# useradd vdsm -u 36 -g 36
# chown -R 36:36 /exports/data
# chmod 0755 /exports/data

# cat << EOF > /etc/exports
# /exports/data     172.29.159.0/24(rw,sync,no_root_squash,no_all_squash)
# EOF

# systemctl restart nfs
# systemctl enable nfs

showmount -e localhost

# install rhv
yum install cockpit-ovirt-dashboard

systemctl enable cockpit.socket
systemctl start cockpit.socket

yum install rhvm-appliance

# rhv install tool ckit
# http://172.29.159.99:9090/

# vnc env
yum -y install tigervnc-server tigervnc gnome-terminal gnome-session gnome-classic-session gnome-terminal nautilus-open-terminal control-center liberation-mono-fonts google-noto-sans-cjk-fonts google-noto-sans-fonts fonts-tweak-tool

yum install -y    qgnomeplatform   xdg-desktop-portal-gtk   NetworkManager-libreswan-gnome   PackageKit-command-not-found   PackageKit-gtk3-module   abrt-desktop   at-spi2-atk   at-spi2-core   avahi   baobab   caribou   caribou-gtk2-module   caribou-gtk3-module   cheese   compat-cheese314   control-center   dconf   empathy   eog   evince   evince-nautilus   file-roller   file-roller-nautilus   firewall-config   firstboot   fprintd-pam   gdm   gedit   glib-networking   gnome-bluetooth   gnome-boxes   gnome-calculator   gnome-classic-session   gnome-clocks   gnome-color-manager   gnome-contacts   gnome-dictionary   gnome-disk-utility   gnome-font-viewer   gnome-getting-started-docs   gnome-icon-theme   gnome-icon-theme-extras   gnome-icon-theme-symbolic   gnome-initial-setup   gnome-packagekit   gnome-packagekit-updater   gnome-screenshot   gnome-session   gnome-session-xsession   gnome-settings-daemon   gnome-shell   gnome-software   gnome-system-log   gnome-system-monitor   gnome-terminal   gnome-terminal-nautilus   gnome-themes-standard   gnome-tweak-tool   nm-connection-editor   orca   redhat-access-gui   sane-backends-drivers-scanners   seahorse   setroubleshoot   sushi   totem   totem-nautilus   vinagre   vino   xdg-user-dirs-gtk   yelp

yum install -y    cjkuni-uming-fonts   dejavu-sans-fonts   dejavu-sans-mono-fonts   dejavu-serif-fonts   gnu-free-mono-fonts   gnu-free-sans-fonts   gnu-free-serif-fonts   google-crosextra-caladea-fonts   google-crosextra-carlito-fonts   google-noto-emoji-fonts   jomolhari-fonts   khmeros-base-fonts   liberation-mono-fonts   liberation-sans-fonts   liberation-serif-fonts   lklug-fonts   lohit-assamese-fonts   lohit-bengali-fonts   lohit-devanagari-fonts   lohit-gujarati-fonts   lohit-kannada-fonts   lohit-malayalam-fonts   lohit-marathi-fonts   lohit-nepali-fonts   lohit-oriya-fonts   lohit-punjabi-fonts   lohit-tamil-fonts   lohit-telugu-fonts   madan-fonts   nhn-nanum-gothic-fonts   open-sans-fonts   overpass-fonts   paktype-naskh-basic-fonts   paratype-pt-sans-fonts   sil-abyssinica-fonts   sil-nuosu-fonts   sil-padauk-fonts   smc-meera-fonts   stix-fonts   thai-scalable-waree-fonts   ucs-miscfixed-fonts   vlgothic-fonts   wqy-microhei-fonts   wqy-zenhei-fonts


vncpasswd

cat << EOF > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
gnome-session &
EOF
chmod +x ~/.vnc/xstartup

vncserver :1 -geometry 1280x800
# 如果你想停掉vnc server，这么做
vncserver -kill :1

firewall-cmd --permanent --add-port=6001/tcp
firewall-cmd --permanent --add-port=5901/tcp
firewall-cmd --reload


```

### redhat-02

```bash
mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://172.29.159.3/wzh/rhel-data/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

systemctl disable firewalld.service
systemctl stop firewalld.service

yum -y install byobu htop glances dstat bmon

hostnamectl set-hostname rhv02.rhv.redhat.ren

# setup time client
yum install -y chrony

/bin/cp -f /etc/chrony.conf /etc/chrony.conf.bak

cat << EOF > /etc/chrony.conf
server 172.29.159.99
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking

nmcli connection modify enp2s0f0 ipv4.dns 172.29.159.99
nmcli connection reload
nmcli connection up enp2s0f0




```

### rhv install

```bash

# on redhat-01
mkdir -p /data/ocp4/ocp4-upi-helpernode-master
cd /data/ocp4/ocp4-upi-helpernode-master
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

# create manager host
# http://172.29.159.99:9090/
```
这个过程其实和vmware的思路是一样的，先创建一个vm，用来作为管理节点。

这个管理节点，rhv里面就叫做self-host engine，创建这个engine要求，有一个dns能解析到 的域名，我们就用 manager.rhv.redhat.ren。然后还需要一个和host网段内的ip地址，这个vm要求能bridge到host网络里面去。

另外还需要一个宿主机host的域名，能够解析到，我们就用rhv01.rhv.redhat.ren了。

然后安装程序，会把这个manager vm解压缩到/var/tmp/下面去，用qemu/kvm启动。

接下来就是storage，在这一步，选择nfs，把ansible脚本弄出来的目录放进去就可以： 172.29.159.99:/exports/data 

点击下一步，等待一段时间，就安装成功了。

vnc

到了这一步，需要浏览器登录rhv manager了，由于代理配置太复杂，我们就简单点，直接用 vnc去宿主机，firefox访问吧

http://manager.rhv.redhat.ren
admin / *****

然后添加另外一个宿主机，computer -> host -> new。这里直接用宿主机ip就可以了。

然后就是添加一个local storage
https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.3/html-single/administration_guide/index#sect-Preparing_and_Adding_Local_Storage

```bash
mkdir -p /data/images
chown 36:36 /data /data/images
chmod 0755 /data /data/images

```





