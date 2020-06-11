# 

## jumpbox

```bash

yum install icedtea-web

# to crmi
rsync -e ssh --info=progress2 -P --delete -arz  /root/data root@172.29.159.3:/home/wzh/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz  /data/ocp4/ root@172.29.159.3:/home/wzh/ocp4/

rsync -e ssh --info=progress2 -P --delete -arz  /data/registry/  root@172.29.159.3:/home/wzh/registry/

rsync -e ssh --info=progress2 -P --delete -arz  /data/is.samples/ root@172.29.159.3:/home/wzh/is.samples/


```

## redhat-01

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

hostnamectl set-hostname redhat-01


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

# nfs server
# https://qizhanming.com/blog/2018/08/08/how-to-install-nfs-on-centos-7
yum -y install nfs-utils 

mkdir -p /exports/data

groupadd kvm -g 36
useradd vdsm -u 36 -g 36
chown -R 36:36 /exports/data
chmod 0755 /exports/data

cat << EOF > /etc/exports
/exports/data     172.29.159.0/24(rw,sync,no_root_squash,no_all_squash)
EOF

systemctl restart nfs
systemctl enable nfs

showmount -e localhost

# install rhv
yum install cockpit-ovirt-dashboard

systemctl enable cockpit.socket
systemctl start cockpit.socket

yum install rhvm-appliance




```

## redhat-02

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

hostnamectl set-hostname redhat-02

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
```