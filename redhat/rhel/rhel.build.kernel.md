# rhel/centos build kernel



## self
```bash
# https://access.redhat.com/articles/3938081
grubby --info=ALL | grep title

# https://blog.packagecloud.io/eng/2015/04/20/working-with-source-rpms/


subscription-manager --proxy=192.168.253.1:5084 register --username **** --password ********


subscription-manager config --rhsm.baseurl=https://cdn.redhat.com
# subscription-manager config --rhsm.baseurl=https://cdn.redhat.com
subscription-manager --proxy=192.168.253.1:5084 refresh

subscription-manager --proxy=192.168.253.1:5084 repos --help

subscription-manager --proxy=192.168.253.1:5084 repos --list > list

cat list | grep 'Repo ID' | grep -v source | grep -v debug

subscription-manager --proxy=192.168.253.1:5084 repos --disable="*"

subscription-manager --proxy=192.168.253.1:5084 repos \
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

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

yum install yum-utils rpm-build

yum list kernel.x86_64

yumdownloader --source kernel.x86_64

rpm -ivh /root/kernel-4.18.0-221.el8.src.rpm

cd /root/rpmbuild/SPECS
# https://stackoverflow.com/questions/13227162/automatically-install-build-dependencies-prior-to-building-an-rpm-package
yum-builddep kernel.spec

rpmbuild -bp --target=x86_64 kernel.spec

# libbabeltrace-devel

# https://www.cnblogs.com/luohaixian/p/9313863.html
KERNELVERION=`uname -r | sed "s/.$(uname -m)//"`
KERNELRV=$(uname -r)
/bin/cp -f /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELRV}/configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELRV}/

/bin/cp -f configs/kernel-4.18.0-`uname -m`.config .config

make oldconfig

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


# x86_64
sed -i '1s/^/# x86_64\n/' .config

/bin/cp -f .config configs/kernel-4.18.0-`uname -m`.config

/bin/cp -f configs/* /root/rpmbuild/SOURCES/

cd /root/rpmbuild/SPECS

# cp kernel.spec kernel.spec.orig
# https://fedoraproject.org/wiki/Building_a_custom_kernel
# sed -i "s/# define buildid \\.local/%define buildid \\.local/" kernel.spec

rpmbuild -bb --target=`uname -m` kernel.spec 2> build-err.log | tee build-out.log

```


## gps
```bash
# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.2/x86_64/packages
# download kernel source rpm 

# rpm -ivh  kernel-4.18.0补全路径（刚才传的源包）
# cd rpmbuild/SPECS  然后执行ls 能看到 kernel.spec文件
rpmbuild -bp --target=x86_64 kernel.spec

# https://www.jianshu.com/p/482d5d68f81f

cd /usr/src/kernels/4.18.0-193.el8.x86_64

# 打开编辑 .config

# 切换路径 rpmbuild/BUILD/kernel（补全）/linux（补全） 
make menuconfig
make


```


