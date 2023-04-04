# rhel9 tips

```bash
export PROXY="127.0.0.1:18801"

subscription-manager register --proxy=$PROXY --auto-attach --username ********* --password ********

subscription-manager repos --proxy=$PROXY --list  > list

# https://docs.fedoraproject.org/en-US/epel/#_el9
subscription-manager repos --proxy=$PROXY --enable codeready-builder-for-rhel-9-$(arch)-rpms

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# cat << EOF > ~/.tmux.conf
# setw -g mode-keys vi
# EOF

# https://centos.pkgs.org/8/epel-x86_64/byobu-5.133-1.el8.noarch.rpm.html
dnf install -y https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/b/byobu-5.133-1.el8.noarch.rpm

dnf install -y htop


```

# kernel source, alma 9

```bash
# on vultr, alma 9

dnf config-manager --set-enabled crb

######################################################
# begin to build kernel
# 真正开始我们的内核编译
# 查找内核版本
yum list kernel.x86_64
# ......
# kernel.x86_64                                                                5.14.0-162.6.1.el9_1                                                                 @baseos 

# 下载内核源码包
yum -y install yum-utils rpm-build 
yumdownloader --source kernel.x86_64

# 安装源码包
rpm -ivh /root/kernel-5.14.0-162.6.1.el9_1.src.rpm

# 安装编译的依赖包
cd /root/rpmbuild/SPECS
# https://stackoverflow.com/questions/13227162/automatically-install-build-dependencies-prior-to-building-an-rpm-package
# 安装辅助包
yum-builddep -y kernel.spec

# 生成配置
rpmbuild -bp --target=x86_64 kernel.spec

# libbabeltrace-devel

# https://www.cnblogs.com/luohaixian/p/9313863.html
KERNELVERION=`uname -r | sed "s/.$(uname -m)//"`
KERNELRV=$(uname -r)
KERNELSV=`echo $KERNELRV | sed 's/_.//'`
/bin/cp -f /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELSV}/configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELSV}/

/bin/cp -f configs/kernel-5.14.0-`uname -m`.config .config
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

/bin/cp -f .config configs/kernel-5.14.0-`uname -m`.config
/bin/cp -f .config configs/kernel-x86_64.config

/bin/cp -f configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/SPECS

# cp kernel.spec kernel.spec.orig
# https://fedoraproject.org/wiki/Building_a_custom_kernel

# 自定义内核名称
sed -i "s/# define buildid \\.local/%define buildid \\.wzh/" kernel.spec

# rpmbuild -bb --target=`uname -m` --without kabichk  kernel.spec 2> build-err.log | tee build-out.log

# rpmbuild -bb --target=`uname -m` --without debug --without debuginfo --without kabichk kernel.spec 2> build-err.log | tee build-out.log

# rpmbuild -bb --target=`uname -m` --with baseonly --without debug --without debuginfo --without kabichk kernel.spec 2> build-err.log | tee build-out.log

rpmbuild -ba --target=`uname -m` kernel.spec

# cd /root/rpmbuild/RPMS/x86_64/

cd /root/rpmbuild/BUILD/kernel-5.14.0-162.6.1.el9_1/linux-5.14.0-162.6.1.el9.x86_64
make clean

git config --global credential.credentialStore cache
git config --global user.email "wangzheng422@gmail.com"

mkdir -p ~/tmp
cd ~/tmp

wget -O gcm-linux_amd64.tar.gz https://github.com/GitCredentialManager/git-credential-manager/releases/download/v2.0.877/gcm-linux_amd64.2.0.877.tar.gz
tar -xvf gcm-linux_amd64.tar.gz  -C /usr/local/bin
git-credential-manager configure

cd ~
git clone https://github.com/wangzheng422/kernel-learn

cd kernel-learn
mv /root/rpmbuild/BUILD/kernel-5.14.0-162.6.1.el9_1/linux-5.14.0-162.6.1.el9.x86_64 ./

git add .
git commit -m 'alma 9'
git push

```

