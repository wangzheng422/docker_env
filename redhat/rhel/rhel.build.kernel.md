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


```


## gps
```bash
# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.2/x86_64/packages
# download kernel source rpm 

# rpm -ivh  kernel-4.18.0补全路径（刚才传的源包）
# cd rpmbuild/SPECS  然后执行ls 能看到 kernel.spec文件
rpmbuild -bp --target=x86_64 kernel.spec

cd /usr/src/kernels/4.18.0-193.el8.x86_64

# 打开编辑 .config

# 切换路径 rpmbuild/BUILD/kernel（补全）/linux（补全） 
make menuconfig
make


```


