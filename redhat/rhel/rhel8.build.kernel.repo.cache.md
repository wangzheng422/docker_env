# RHEL/centos 8 build kernel

本文描述如何在rhel8上编译自定义的内核。

业务背景是，客户需要使用mellanox网卡高级功能，需要kernel打开相应的选项，才可以使用，所以我们就编译一个新的内核出来。

## 讲解视频

[<kbd><img src="imgs/2020-09-28-10-33-03.png" width="600"></kbd>](https://www.bilibili.com/video/BV1ya4y1j7R3/)

- [bilibili](https://www.bilibili.com/video/BV1ya4y1j7R3/)
- [xigua](https://www.ixigua.com/6877362547456999943)
- [youtube](https://youtu.be/jYCUVSv4Faw)

## 实验步骤

### 先做一个离线repo源
由于我们的目标编译环境，是一个外网隔离的主机环境，那么我们就需要给目标环境准备一个离线更新源，这个章节，我们就在公网环境里面，来准备一个rhel8的离线更新源。
```bash
# https://access.redhat.com/articles/3938081
# grubby --info=ALL | grep title

# https://blog.packagecloud.io/eng/2015/04/20/working-with-source-rpms/

export PROXY="127.0.0.1:18801"
export PROXY="192.168.253.1:5084"

# 由于需要rhel8.3，我们需要注册特殊的订阅。
subscription-manager --proxy=$PROXY register --auto-attach --username **** --password ********

subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com
# subscription-manager config --rhsm.baseurl=https://cdn.redhat.com
# subscription-manager --proxy=$PROXY refresh

# subscription-manager --proxy=$PROXY repos --help

# subscription-manager --proxy=$PROXY repos --list > list

# cat list | grep 'Repo ID' | grep -v source | grep -v debug
# cat list | grep 'Repo ID' | grep source

subscription-manager --proxy=$PROXY repos --disable="*"

subscription-manager --proxy=$PROXY repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-baseos-source-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhel-8-for-x86_64-supplementary-rpms" \
    --enable="codeready-builder-for-rhel-8-x86_64-rpms" \
    # --enable="rhel-8-for-x86_64-rt-beta-rpms" \
    # --enable="rhel-8-for-x86_64-highavailability-beta-rpms" \
    # --enable="rhel-8-for-x86_64-nfv-beta-rpms" \
    # --enable="fast-datapath-beta-for-rhel-8-x86_64-rpms" \
    # --enable="dirsrv-beta-for-rhel-8-x86_64-rpms" \
    # ansible-2.9-for-rhel-8-x86_64-rpms

# cat << EOF >> /etc/dnf/dnf.conf
# proxy=http://192.168.253.1:5084
# EOF
cat << EOF >> /etc/dnf/dnf.conf
fastestmirror=1
EOF

# add ubi support
cat << EOF > /etc/yum.repos.d/ubi.repo
[ubi-8-baseos]
name=ubi-8-baseos
baseurl=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi8/8/x86_64/baseos/os
enabled=1
gpgcheck=1

[ubi-8-appstream]
name=ubi-8-appstream
baseurl=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi8/8/x86_64/appstream/os
enabled=1
gpgcheck=1

[ubi-8-codeready-builder]
name=ubi-8-codeready-builder
baseurl=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi8/8/x86_64/codeready-builder/os/
enabled=1
gpgcheck=1

EOF


# 编译内核，需要rhel8里面的epel的包
# yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum -y install yum-utils rpm-build tar pigz dnf-plugins-core htop byobu  tlog cockpit-session-recording glances wget tigervnc-server tigervnc tigervnc-server-module createrepo

dnf -y install cockpit cockpit-dashboard cockpit-machines

yum -y install virt-install virt-viewer libguestfs-tools virt-manager

dnf -y module install virt

yum -y groupinstall 'Server with GUI'

yum -y update

systemctl enable --now cockpit.socket
systemctl disable --now firewalld

systemctl enable --now libvirtd.service

pvcreate -f /dev/nvme0n1
vgcreate nvme /dev/nvme0n1
lvcreate -y -L 300G -n data nvme

mkfs.xfs /dev/nvme/data
mount /dev/nvme/data /data

mkdir -p /data/dnf
cd /data/dnf

dnf reposync -m --download-metadata --delete -n
# dnf reposync -m --download-metadata -n

# dnf reposync --repoid=rhel-8-for-x86_64-baseos-rpms -m --download-metadata
# createrepo ./

cd /data
tar -cvf - dnf/ | pigz -c > rhel8.dnf.tgz

# 按照5G大小切分更新源的包，并上传百度盘
split -b 5000m rhel8.dnf.tgz rhel8.dnf.tgz.

# 用下载好的更新包，创建ftp的更新源，准备kvm进行内核编译测试
dnf -y install vsftpd
mkdir -p /var/ftp/dnf
mount --bind /data/dnf /var/ftp/dnf
chcon -R -t public_content_t /var/ftp/dnf

sed -i "s/anonymous_enable=NO/anonymous_enable=YES/" /etc/vsftpd/vsftpd.conf

systemctl enable --now vsftpd
systemctl restart vsftpd

```

### create a disconnected kvm
在这里，我们创建一个外网隔离的kvm，用宿主机上的ftp更新源来更新系统，并编译内核。本章节，我们来创建这个kvm虚拟机。
```bash
# 先在宿主机上准备vncserver环境，
# 注意rhel8情况下，vncserver的配置方法改变了。
vncpasswd

cat << EOF > ~/.vnc/xstartup
#!/bin/sh
# unset SESSION_MANAGER
# unset DBUS_SESSION_BUS_ADDRESS
vncconfig &
# gnome-session &
EOF
chmod +x ~/.vnc/xstartup

cat << EOF > ~/.vnc/config
session=gnome
securitytypes=vncauth,tlsvnc
desktop=sandbox
geometry=1280x800
alwaysshared
EOF

cat /usr/share/doc/tigervnc/HOWTO.md

cat << EOF >> /etc/tigervnc/vncserver.users
:1=root
EOF

systemctl start vncserver@:1

systemctl stop vncserver@:1

journalctl -u vncserver@:1

# 给kvm准备一个逻辑卷做启动盘。
lvremove -f nvme/data01
lvcreate -y -L 72G -n data01 nvme

# 创建一个宿主机host-only的网络
cat << EOF >  /data/virt-net.xml
<network>
  <name>openshift4</name>
  <bridge name='openshift4' stp='on' delay='0'/>
  <domain name='openshift4'/>
  <ip address='192.168.7.1' netmask='255.255.255.0'>
  </ip>
</network>
EOF

virsh net-define --file /data/virt-net.xml
virsh net-autostart openshift4
virsh net-start openshift4

# 创建并运行rhel8主机，开始安装
virt-install --name=rhel8-kernel --vcpus=16 --ram=32768 \
  --disk path=/dev/nvme/data01,device=disk,bus=virtio,format=raw \
  --network network=openshift4,model=virtio \
  --os-variant rhel8.3 \
  --boot menu=on --location /data/rhel-8.3-x86_64-dvd.iso

# 后续宿主机重启后，这样启动kvm
virsh start rhel8-kernel

```

### build the kernel
以上，我们就准备好了离线的kvm测试机，让我们在这个kvm里面，开始我们的内核编译。
```bash
#####################################################
# login to the vm
# 使用宿主机上的ftp更新源
mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

export YUMIP="192.168.7.1"
cat << EOF > /etc/yum.repos.d/remote.repo
[remote-epel]
name=epel
baseurl=ftp://${YUMIP}/dnf/epel
enabled=1
gpgcheck=0

[remote-epel-modular]
name=epel-modular
baseurl=ftp://${YUMIP}/dnf/epel-modular
enabled=1
gpgcheck=0

[remote-appstream]
name=appstream
baseurl=ftp://${YUMIP}/dnf/rhel-8-for-x86_64-appstream-rpms
enabled=1
gpgcheck=0

[remote-baseos]
name=baseos
baseurl=ftp://${YUMIP}/dnf/rhel-8-for-x86_64-baseos-rpms
enabled=1
gpgcheck=0

[remote-baseos-source]
name=baseos-source
baseurl=ftp://${YUMIP}/dnf/rhel-8-for-x86_64-baseos-source-rpms
enabled=1
gpgcheck=0

[remote-supplementary]
name=supplementary
baseurl=ftp://${YUMIP}/dnf/rhel-8-for-x86_64-supplementary-rpms
enabled=1
gpgcheck=0

[remote-codeready-builder]
name=supplementary
baseurl=ftp://${YUMIP}/dnf/codeready-builder-for-rhel-8-x86_64-rpms
enabled=1
gpgcheck=0

EOF

yum clean all
yum makecache
yum repolist

yum -y update

reboot

######################################################
# begin to build kernel
# 真正开始我们的内核编译
# 查找内核版本
yum list kernel.x86_64

# 下载内核源码包
yum -y install yum-utils rpm-build 
yumdownloader --source kernel.x86_64

# 安装源码包
rpm -ivh /root/kernel-4.18.0-240.1.1.el8_3.src.rpm

# 安装编译的依赖包
cd /root/rpmbuild/SPECS
# https://stackoverflow.com/questions/13227162/automatically-install-build-dependencies-prior-to-building-an-rpm-package
# 安装辅助包
yum-builddep kernel.spec

# 生成配置
rpmbuild -bp --target=x86_64 kernel.spec

# libbabeltrace-devel

# https://www.cnblogs.com/luohaixian/p/9313863.html
KERNELVERION=`uname -r | sed "s/.$(uname -m)//"`
KERNELRV=$(uname -r)
KERNELSV=`echo $KERNELRV | sed 's/_.//'`
/bin/cp -f /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELSV}/configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELSV}/

/bin/cp -f configs/kernel-4.18.0-`uname -m`.config .config
# cp /boot/config-`uname -r`   .config

make oldconfig

# 按照编译内核的需求，调整内核参数
# 自定义配置，请观看视频
make menuconfig

# vi .config

# CONFIG_MLX5_TC_CT=y
# CONFIG_NET_ACT_CT=m
# CONFIG_SKB_EXTENSIONS=y
# CONFIG_NET_TC_SKB_EXT=y
# CONFIG_NF_FLOW_TABLE=m
# CONFIG_NF_FLOW_TABLE_IPV4=m  x
# CONFIG_NF_FLOW_TABLE_IPV6=m  x
# CONFIG_NF_FLOW_TABLE_INET=m
# CONFIG_NET_ACT_CONNMARK=m x
# CONFIG_NET_ACT_IPT=m  x
# CONFIG_NET_EMATCH_IPT=m   x
# CONFIG_NET_ACT_IFE=m  x

# 指明编译x86
# x86_64
sed -i '1s/^/# x86_64\n/' .config

/bin/cp -f .config configs/kernel-4.18.0-`uname -m`.config
/bin/cp -f .config configs/kernel-x86_64.config

/bin/cp -f configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/SPECS

# cp kernel.spec kernel.spec.orig
# https://fedoraproject.org/wiki/Building_a_custom_kernel

# 自定义内核名称
sed -i "s/# define buildid \\.local/%define buildid \\.wzh/" kernel.spec

# rpmbuild -bb --target=`uname -m` --without kabichk  kernel.spec 2> build-err.log | tee build-out.log

# rpmbuild -bb --target=`uname -m` --without debug --without debuginfo --without kabichk kernel.spec 2> build-err.log | tee build-out.log

rpmbuild -bb --target=`uname -m` --with baseonly --without debug --without debuginfo --without kabichk kernel.spec 2> build-err.log | tee build-out.log

cd /root/rpmbuild/RPMS/x86_64/

# 安装编译的内核
# 由于每次编译内核的名字都不一样，这里需要手动更新一下名字
INSTALLKV=4.18.0-240.1.1.el8.wzh

yum install ./kernel-$INSTALLKV.x86_64.rpm ./kernel-core-$INSTALLKV.x86_64.rpm ./kernel-modules-$INSTALLKV.x86_64.rpm

# 重启以后，检查内核模块激活
grep -R --include=Makefile CONFIG_NET_ACT_IFE
# rpmbuild/BUILD/kernel-4.18.0-221.el8/linux-4.18.0-221.el8.wzh.x86_64/net/sched/Makefile:obj-$(CONFIG_NET_ACT_IFE)	+= act_ife.o
modprobe act_ife
lsmod | grep act_ife

```

## 下载和使用离线更新源
本次实验 rhel8 的离线更新源，在这里下载：

链接: https://pan.baidu.com/s/1B4bRcnpyAv8L-GzPB32Orw  密码: r9ck

```bash
# 下载以后，这样使用
cat rhel8.dnf.tgz.* > rhel8.dnf.tgz

tar zvxf rhel8.dnf.tgz

# 使用解压缩后的 dnf 目录，挂在到ftp或者http服务目录上
# 更新主机的 /etc/yum.repos.d/remote.repo 即可


```