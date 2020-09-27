# rhel/centos build kernel



## self
```bash
# https://access.redhat.com/articles/3938081
# grubby --info=ALL | grep title

# https://blog.packagecloud.io/eng/2015/04/20/working-with-source-rpms/

subscription-manager --proxy=192.168.253.1:5084 register --username **** --password ********

# subscription-manager config --rhsm.baseurl=https://cdn.redhat.com
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

cat << EOF >> /etc/dnf/dnf.conf
proxy=http://192.168.253.1:5084
EOF

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum -y install yum-utils rpm-build

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

sed -i "s/# define buildid \\.local/%define buildid \\.wzh/" kernel.spec

rpmbuild -bb --target=`uname -m` --without kabichk  kernel.spec 2> build-err.log | tee build-out.log

rpmbuild -bb --target=`uname -m` --without debug --without debuginfo --without kabichk kernel.spec 2> build-err.log | tee build-out.log

rpmbuild -bb --target=`uname -m` --with baseonly --without debug --without debuginfo --without kabichk kernel.spec 2> build-err.log | tee build-out.log

cd /root/rpmbuild/RPMS/x86_64/

yum install ./kernel-4.18.0-221.el8.x86_64.rpm



```


