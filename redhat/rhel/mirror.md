# how to mirror for rhel-like distribute

# rocky linux 8

```bash

cat << EOF >> /etc/dnf/dnf.conf

fastestmirror=true

EOF

export http_proxy=http://10.147.17.89:5085
export https_proxy=http://10.147.17.89:5085

dnf makecache

dnf install -y open-vm-tools

mkdir -p /mnt/hgfs/mirror
vmhgfs-fuse .host:/mirror /mnt/hgfs/mirror

# vmhgfs-fuse .host:/mirror /mnt/hgfs/mirror -o subtype=vmhgfs-fuse,allow_other

mkdir -p /mnt/hgfs/mirror/rocky-8
cd /mnt/hgfs/mirror/rocky-8

dnf repolist --all
# repo id                                                          repo name                                                                                         status
# appstream                                                        Rocky Linux 8 - AppStream                                                                         enabled
# appstream-debug                                                  Rocky Linux 8 - AppStream - Source                                                                disabled
# appstream-source                                                 Rocky Linux 8 - AppStream - Source                                                                disabled
# baseos                                                           Rocky Linux 8 - BaseOS                                                                            enabled
# baseos-debug                                                     Rocky Linux 8 - BaseOS - Source                                                                   disabled
# baseos-source                                                    Rocky Linux 8 - BaseOS - Source                                                                   disabled
# devel                                                            Rocky Linux 8 - Devel WARNING! FOR BUILDROOT AND KOJI USE                                         disabled
# extras                                                           Rocky Linux 8 - Extras                                                                            enabled
# ha                                                               Rocky Linux 8 - HighAvailability                                                                  disabled
# ha-debug                                                         Rocky Linux 8 - High Availability - Source                                                        disabled
# ha-source                                                        Rocky Linux 8 - High Availability - Source                                                        disabled
# media-appstream                                                  Rocky Linux 8 - Media - AppStream                                                                 disabled
# media-baseos                                                     Rocky Linux 8 - Media - BaseOS                                                                    disabled
# nfv                                                              Rocky Linux 8 - NFV                                                                               disabled
# plus                                                             Rocky Linux 8 - Plus                                                                              disabled
# powertools                                                       Rocky Linux 8 - PowerTools                                                                        disabled
# powertools-debug                                                 Rocky Linux 8 - PowerTools - Source                                                               disabled
# powertools-source                                                Rocky Linux 8 - PowerTools - Source                                                               disabled
# resilient-storage                                                Rocky Linux 8 - ResilientStorage                                                                  disabled
# resilient-storage-debug                                          Rocky Linux 8 - Resilient Storage - Source                                                        disabled
# resilient-storage-source                                         Rocky Linux 8 - Resilient Storage - Source                                                        disabled
# rt                                                               Rocky Linux 8 - Realtime

dnf reposync --repoid=baseos -m --download-metadata --delete -n
dnf reposync --repoid=appstream -m --download-metadata --delete -n
# dnf reposync --repoid=devel -m --download-metadata --delete -n
dnf reposync --repoid=extras -m --download-metadata --delete -n
dnf reposync --repoid=ha -m --download-metadata --delete -n
dnf reposync --repoid=nfv -m --download-metadata --delete -n
dnf reposync --repoid=plus -m --download-metadata --delete -n
dnf reposync --repoid=powertools -m --download-metadata --delete -n
dnf reposync --repoid=resilient-storage -m --download-metadata --delete -n
dnf reposync --repoid=rt -m --download-metadata --delete -n

dnf install -y epel-release
dnf update -y

cat << EOF >> /etc/dnf/dnf.conf

fastestmirror=true

EOF

export http_proxy=http://10.147.17.89:5085
export https_proxy=http://10.147.17.89:5085

dnf makecache

dnf reposync --repoid=epel -m --download-metadata --delete -n


```

## no use

```bash

mkdir -p /etc/yum.repos.d.bak/
/bin/cp -f /etc/yum.repos.d/* /etc/yum.repos.d.bak/

# /bin/rm -f /etc/yum.repos.d/*
# /bin/cp -f /etc/yum.repos.d.bak/* /etc/yum.repos.d/

sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.nju.edu.cn/rocky|g' \
    -i.bak \
    /etc/yum.repos.d/[Rr]ocky*.repo

dnf makecache

```

# centos 7

```bash

yum groupinstall -y 'Infrastructure Server'

yum install -y yum-utils createrepo open-vm-tools

mkdir -p /mnt/hgfs/mirror
vmhgfs-fuse .host:/mirror /mnt/hgfs/mirror

mkdir -p /mnt/hgfs/mirror/centos-7
cd /mnt/hgfs/mirror/centos-7

reposync -n -d -l -m --download-metadata --repoid=base --repoid=extras --repoid=updates

export http_proxy=http://10.147.17.89:5085
export https_proxy=http://10.147.17.89:5085

yum install -y epel-release
yum update -y

reposync -n -d -l -m --download-metadata --repoid=epel

# createrepo --groupfile /path/to/local/repo/centos7/repodata/*comps*.xml -g /path/to/local/repo/centos7/repodata/*comps*.xml /path/to/local/repo/centos7

cd base
createrepo --groupfile comps.xml ./

cd ../extras
createrepo ./

cd ../updates
createrepo ./

cd ../epel
createrepo --groupfile comps.xml ./



```

# rhel 8

```bash

export http_proxy=http://10.147.17.89:5085
export https_proxy=http://10.147.17.89:5085

subscription-manager release --set=8

dnf install -y open-vm-tools

subscription-manager repos --list

mkdir -p /mnt/hgfs/mirror
vmhgfs-fuse .host:/mirror /mnt/hgfs/mirror

mkdir -p /mnt/hgfs/mirror/rhel-8
cd /mnt/hgfs/mirror/rhel-8

unset http_proxy
unset https_proxy

dnf reposync --repoid rhel-8-for-x86_64-baseos-rpms -m --download-metadata --delete -n
dnf reposync --repoid=rhel-8-for-x86_64-appstream-rpms -m --download-metadata --delete -n
dnf reposync --repoid=rhel-8-for-x86_64-rt -m --download-metadata --delete -n
dnf reposync --repoid=rhel-8-for-x86_64-nfv-rpms -m --download-metadata --delete -n
dnf reposync --repoid=advanced-virt-for-rhel-8-x86_64-rpms -m --download-metadata --delete -n
dnf reposync --repoid=fast-datapath-for-rhel-8-x86_64-rpms -m --download-metadata --delete -n
dnf reposync --repoid=codeready-builder-for-rhel-8-x86_64-rpms -m --download-metadata --delete -n



```

# search

```bash

yum provides \*bin/htpasswd

```


# end