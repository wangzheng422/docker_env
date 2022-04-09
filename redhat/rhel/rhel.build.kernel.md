# RHEL/centos 8 build kernel

本文描述如何在rhel8上编译自定义的内核。

业务背景是，客户需要使用mellanox网卡高级功能，需要kernel打开相应的选项，才可以使用，所以我们就编译一个新的内核出来。

## 讲解视频

[<kbd><img src="imgs/2020-09-28-10-33-03.png" width="600"></kbd>](https://www.bilibili.com/video/BV1ya4y1j7R3/)

- [bilibili](https://www.bilibili.com/video/BV1ya4y1j7R3/)
- [xigua](https://www.ixigua.com/6877362547456999943)
- [youtube](https://youtu.be/jYCUVSv4Faw)

## 实验步骤

```bash
# https://access.redhat.com/articles/3938081
# grubby --info=ALL | grep title

# https://blog.packagecloud.io/eng/2015/04/20/working-with-source-rpms/

export PROXY="192.168.253.1:5085"
export PROXY="192.168.203.1:5085"

# 由于需要rhel8.3，而当前8.3还是beta状态，我们需要注册特殊的订阅。
subscription-manager --proxy=$PROXY register --username **** --password ********

# subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com
# subscription-manager config --rhsm.baseurl=https://cdn.redhat.com
subscription-manager --proxy=$PROXY refresh

subscription-manager --proxy=$PROXY repos --help

subscription-manager --proxy=$PROXY repos --list > list

cat list | grep 'Repo ID' | grep -v source | grep -v debug

subscription-manager --proxy=$PROXY repos --disable="*"

subscription-manager --proxy=$PROXY repos \
    --enable="rhel-8-for-x86_64-baseos-beta-rpms" \
    --enable="rhel-8-for-x86_64-appstream-beta-rpms" \
    --enable="rhel-8-for-x86_64-supplementary-beta-rpms" \
    --enable="rhel-8-for-x86_64-rt-beta-rpms" \
    --enable="rhel-8-for-x86_64-highavailability-beta-rpms" \
    --enable="rhel-8-for-x86_64-nfv-beta-rpms" \
    --enable="fast-datapath-beta-for-rhel-8-x86_64-rpms" \
    --enable="codeready-builder-beta-for-rhel-8-x86_64-rpms" \
    # --enable="dirsrv-beta-for-rhel-8-x86_64-rpms" \
    # ansible-2.9-for-rhel-8-x86_64-rpms

cat << EOF >> /etc/dnf/dnf.conf
proxy=http://$PROXY
EOF

# 编译内核，需要rhel7, rhel8里面的epel的包
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum -y install yum-utils rpm-build

yum list kernel.x86_64

# 下载内核源码包
yumdownloader --source kernel.x86_64

# 安装源码包
rpm -ivh /root/kernel-4.18.0-221.el8.src.rpm

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
/bin/cp -f /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELRV}/configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELRV}/

/bin/cp -f configs/kernel-4.18.0-`uname -m`.config .config
# cp /boot/config-`uname -r`   .config

make oldconfig
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
INSTALLKV=4.18.0-221.el8.wzh

yum install ./kernel-$INSTALLKV.x86_64.rpm ./kernel-core-$INSTALLKV.x86_64.rpm ./kernel-modules-$INSTALLKV.x86_64.rpm

# 重启以后，检查内核模块激活
grep -R --include=Makefile CONFIG_NET_ACT_IFE
# rpmbuild/BUILD/kernel-4.18.0-221.el8/linux-4.18.0-221.el8.wzh.x86_64/net/sched/Makefile:obj-$(CONFIG_NET_ACT_IFE)	+= act_ife.o
modprobe act_ife
lsmod | grep act_ife

```

本次实验编译完成的rhel kernel的包，在这里下载：

链接: https://pan.baidu.com/s/1AG07HxpXy9hoCLMq9qXi0Q  密码: 7hkt
--来自百度网盘超级会员V3的分享


