# cmri labs install

## jumpbox

```bash

yum install icedtea-web

# to crmi
rsync -e ssh --info=progress2 -P --delete -arz  /root/data root@172.29.159.3:/home/wzh/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz  /data/ocp4/ root@172.29.159.3:/home/wzh/ocp4/

rsync -e ssh --info=progress2 -P --delete -arz  /data/registry/  root@172.29.159.3:/home/wzh/registry/

rsync -e ssh --info=progress2 -P --delete -arz  /data/is.samples/ root@172.29.159.3:/home/wzh/is.samples/


```
## try with ovs
https://pinrojas.com/2017/05/03/how-to-use-virt-install-to-connect-at-openvswitch-bridges/

https://blog.csdn.net/wuliangtianzu/article/details/81870551

https://stackoverflow.com/questions/30622680/kvm-ovs-bridged-network-how-to-configure

https://stackoverflow.com/questions/31566658/setup-private-networking-between-two-hosts-and-two-vms-with-libvirt-openvswitc

follow this to setup ovs network:
https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.4/4.4.ovs.md

```bash
# on redhat-01
timedatectl set-timezone Asia/Shanghai

pvcreate /dev/sdb
vgcreate datavg /dev/sdb

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


# on redhat-02

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





