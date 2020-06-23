# poc for sc
- [poc for sc](#poc-for-sc)
  - [rhel host maintain](#rhel-host-maintain)
    - [aliyun host](#aliyun-host)
    - [helper host](#helper-host)
    - [helper host day 2](#helper-host-day-2)
    - [bootstrap host](#bootstrap-host)
    - [master0 host](#master0-host)
    - [master1 host](#master1-host)
    - [master2 host](#master2-host)
    - [infra0 host](#infra0-host)
    - [infra1 host](#infra1-host)
    - [worker-0 host](#worker-0-host)
    - [worker-0 disk](#worker-0-disk)
    - [worker-1 host](#worker-1-host)
    - [worker-1 disk](#worker-1-disk)
    - [worker-1 nic bond](#worker-1-nic-bond)
    - [worker-2 host](#worker-2-host)
    - [worker-2 disk](#worker-2-disk)
    - [worker-2 disk tunning](#worker-2-disk-tunning)
    - [worker-2 nic bond](#worker-2-nic-bond)
    - [worker-3 host](#worker-3-host)
    - [worker-3 disk](#worker-3-disk)
  - [install ocp](#install-ocp)
    - [helper node day1](#helper-node-day1)
    - [helper node day1 oper](#helper-node-day1-oper)
    - [helper node day 2 sec](#helper-node-day-2-sec)
    - [helper node quay](#helper-node-quay)
    - [helper node zte oper](#helper-node-zte-oper)
    - [helper host add vm-router](#helper-host-add-vm-router)
    - [helper node zte tcp-router](#helper-node-zte-tcp-router)
    - [helper node cluster tunning](#helper-node-cluster-tunning)
    - [helper node local storage](#helper-node-local-storage)
    - [bootstrap node day1](#bootstrap-node-day1)
    - [master1 node day1](#master1-node-day1)
    - [master0 node day1](#master0-node-day1)
    - [master2 node day1](#master2-node-day1)
    - [infra0 node day1](#infra0-node-day1)
    - [infra1 node day1](#infra1-node-day1)
    - [worker-0 day2 oper](#worker-0-day2-oper)
    - [worker-1 day2 oper](#worker-1-day2-oper)
    - [worker-2 day2 oper](#worker-2-day2-oper)
  - [tips](#tips)

## rhel host maintain

### aliyun host

```bash

ssh-copy-id root@

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

EOF

export VULTR_HOST=helper.hsc.redhat.ren

rsync -e ssh --info=progress2 -P --delete -arz /data/rhel-data/data ${VULTR_HOST}:/data/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz /data/registry ${VULTR_HOST}:/data/

rsync -e ssh --info=progress2 -P --delete -arz /data/ocp4 ${VULTR_HOST}:/data/

rsync -e ssh --info=progress2 -P --delete -arz /data/is.samples ${VULTR_HOST}:/data/

cd /data
tar -cvf - registry/ | pigz -c > registry.tgz
tar -cvf - ocp4/ | pigz -c > ocp4.tgz
tar -cvf - data/ | pigz -c > rhel-data.tgz
tar -cvf - is.samples/ | pigz -c > /data_hdd/down/is.samples.tgz

```

### helper host

```bash
######################################################
# on helper

find . -name vsftp*
yum -y install ./data/rhel-7-server-rpms/Packages/vsftpd-3.0.2-25.el7.x86_64.rpm
systemctl start vsftpd
systemctl restart vsftpd
systemctl enable vsftpd

firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload

mv data /var/ftp/
chcon -R -t public_content_t /var/ftp/data

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname helper.hsc.redhat.ren
nmcli connection modify em1 ipv4.dns 114.114.114.114
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lsblk | grep 446 | awk '{print $1}' | wc -l
# 12

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_configure-mange-raid-configuring-and-managing-logical-volumes
yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgs

lvcreate --type raid10 -l 100%FREE --stripes 6 -n datalv datavg

umount /data_hdd
lvremove /dev/datavg/datalv

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                   xfs     defaults        0 0

EOF

mount -a

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -h -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm 5
iostat -m -x dm-24 5

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

firewall-cmd --get-zones
# block dmz drop external home internal public trusted work
firewall-cmd --zone=public --list-all

firewall-cmd --permanent --zone=public --remove-port=2049/tcp

firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="2049" protocol="tcp" source address="117.177.241.0/24" accept'
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="2049" protocol="tcp" source address="39.137.101.0/24" accept'

# firewall-cmd --permanent --zone=public --add-port=4443/tcp

firewall-cmd --reload

showmount -a
exportfs -s

cd /data_ssd/
scp *.tgz root@117.177.241.17:/data_hdd/down/

# https://access.redhat.com/solutions/3341191
# subscription-manager register --org=ORG ID --activationkey= Key Name
cat /var/log/rhsm/rhsm.log

subscription-manager config --rhsm.manage_repos=0
cp /etc/yum/pluginconf.d/subscription-manager.conf /etc/yum/pluginconf.d/subscription-manager.conf.orig
cat << EOF  > /etc/yum/pluginconf.d/subscription-manager.conf
[main]
enabled=0
EOF

# https://access.redhat.com/products/red-hat-insights/#getstarted
subscription-manager register --auto-attach
yum --disableplugin=subscription-manager install insights-client
insights-client --register

yum --disableplugin=subscription-manager install ncdu

```

### helper host day 2 

```bash
####################################
# anti scan
firewall-cmd --permanent --zone=public --remove-rich-rule='rule family="ipv4" port port="2049" protocol="tcp" source address="117.177.241.0/24" accept'
firewall-cmd --permanent --zone=public --remove-rich-rule='rule family="ipv4" port port="2049" protocol="tcp" source address="39.137.101.0/24" accept'

firewall-cmd --permanent --new-ipset=my-allow-list --type=hash:net
firewall-cmd --permanent --get-ipsets

cat > /root/iplist.txt <<EOL
127.0.0.1/32
223.87.20.0/24
117.177.241.0/24
39.134.200.0/24
39.134.201.0/24
39.137.101.0/24
192.168.7.0/24
112.44.102.224/27
47.93.86.113/32
221.226.0.75/32
210.21.236.182/32
61.132.54.0/24
112.44.102.228/32
223.87.20.7/32
10.88.0.0/16
223.86.0.14/32
39.134.204.0/24
EOL

firewall-cmd --permanent --ipset=my-allow-list --add-entries-from-file=iplist.txt

firewall-cmd --permanent --ipset=my-allow-list --get-entries

firewall-cmd --permanent --zone=trusted --add-source=ipset:my-allow-list 
firewall-cmd --reload

firewall-cmd --list-all
firewall-cmd --get-active-zones

firewall-cmd --zone=block --change-interface=em1

firewall-cmd --set-default-zone=block
firewall-cmd --runtime-to-permanent
firewall-cmd --reload

# setup time server
/bin/cp -f /etc/chrony.conf /etc/chrony.conf.bak

cat << EOF > /etc/chrony.conf
server 0.rhel.pool.ntp.org iburst
server 1.rhel.pool.ntp.org iburst
server 2.rhel.pool.ntp.org iburst
server 3.rhel.pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
allow 39.134.0.0/16
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking

useradd -m zte

groupadd docker
usermod -aG docker zte

# https://github.com/containers/libpod/issues/5049
loginctl enable-linger zte
su -l zte

# https://www.redhat.com/en/blog/preview-running-containers-without-root-rhel-76
echo 10000 > /proc/sys/user/max_user_namespaces

####################################
## trust podman
firewall-cmd --permanent --zone=trusted --add-interface=cni0
firewall-cmd --permanent --zone=trusted --remove-interface=cni0

firewall-cmd --reload

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
allow 39.134.0.0/16
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
```


### bootstrap host

```bash
######################################################
# bootstrap

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname bootstrap.hsc.redhat.ren

nmcli connection modify em1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lsblk | grep 446 | awk '{print $1}' | wc -l
# 12

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_configure-mange-raid-configuring-and-managing-logical-volumes
yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgs

lvcreate --type raid10 -l 100%FREE --stripes 6 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                   xfs     defaults        0 0

EOF

mount -a

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -h -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm 5
iostat -m -x dm-24 5

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
```

### master0 host

```bash
#####################################################
# master0

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname master0.hsc.redhat.ren

nmcli connection modify em1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lsblk | grep 446 | awk '{print $1}' | wc -l
# 12

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_configure-mange-raid-configuring-and-managing-logical-volumes
yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgs

lvcreate --type raid0 -l 100%FREE --stripes 12 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data
mkdir -p /data_hdd

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data_hdd                  xfs     defaults        0 0

EOF

mount -a

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
```

### master1 host

```bash
######################################################
# master1

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname master1.hsc.redhat.ren

nmcli connection modify em1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

mkdir -p /data_hdd
mkfs.xfs -f /dev/sdb

cat << EOF >> /etc/fstab
/dev/sdb /data_hdd                   xfs     defaults        0 0
EOF

mount -a

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
```

### master2 host

```bash
######################################################
# master2

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname master2.hsc.redhat.ren

nmcli connection modify em1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true
EOF

systemctl enable fail2ban
systemctl restart fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

fail2ban-client status
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lsblk | grep 446 | awk '{print $1}' | wc -l
# 12

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_configure-mange-raid-configuring-and-managing-logical-volumes
yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgs

lvcreate --type raid0 -l 100%FREE --stripes 12 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data
mkdir -p /data_hdd

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data_hdd                   xfs     defaults        0 0

EOF

mount -a

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm 5
iostat -m -x dm-12 5

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
```

### infra0 host

```bash
######################################################
# infra0

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname infra0.hsc.redhat.ren

nmcli connection modify em1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lsblk | grep 446 | awk '{print $1}' | wc -l
# 12

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_configure-mange-raid-configuring-and-managing-logical-volumes
yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgs

lvcreate --type raid0 -l 100%FREE --stripes 12 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data
mkdir -p /data_hdd

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                   xfs     defaults        0 0

EOF

mount -a

# https://access.redhat.com/solutions/769403
fuser -km /data
lvremove -f datavg/datalv
vgremove datavg
pvremove /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lvcreate --type raid0 -L 400G --stripes 12 -n monitorlv datavg

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm 5
iostat -m -x dm-12 5

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
```

### infra1 host

```bash
######################################################
# infra1

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y update

hostnamectl set-hostname infra1.hsc.redhat.ren

nmcli connection modify em1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up em1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lsblk | grep 446 | awk '{print $1}' | wc -l
# 12

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_configure-mange-raid-configuring-and-managing-logical-volumes
yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

vgs

lvcreate --type raid0 -l 100%FREE --stripes 12 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data
mkdir -p /data_hdd

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                   xfs     defaults        0 0

EOF

mount -a

# https://access.redhat.com/solutions/769403
fuser -km /data
lvremove -f datavg/datalv
vgremove datavg
pvremove /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm
lvcreate --type raid0 -L 400G --stripes 12 -n monitorlv datavg

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm 5
iostat -m -x dm-12 5

yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking

```

### worker-0 host

```bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum --disableplugin=subscription-manager  repolist

yum -y update

hostnamectl set-hostname worker-0.ocpsc.redhat.ren

nmcli connection modify enp3s0f0 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up enp3s0f0

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 446 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk
lsblk | grep 446 | awk '{print $1}' | wc -l
# 11

yum install -y lvm2

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk 

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

vgs

lvcreate --type raid0 -l 100%FREE --stripes 10 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                  xfs     defaults        0 0

EOF

mount -a

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk 5
iostat -m -x dm-10 5



####################################
# ntp
yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

systemctl disable --now firewalld.service

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking

#######################################
# nic bond
cat << EOF > /root/nic.bond.sh
#!/bin/bash

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete uuid ${i} ; done 

nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad \
    ipv4.method 'manual' \
    ipv4.address '39.137.101.28/25' \
    ipv4.gateway '39.137.101.126' \
    ipv4.dns '117.177.241.16'
    
nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3
    
nmcli con add type bond-slave ifname enp3s0f0 con-name enp3s0f0 master bond0
nmcli con add type bond-slave ifname enp3s0f1 con-name enp3s0f1 master bond0

# nmcli con down enp3s0f0 && nmcli con start enp3s0f0
# nmcli con down enp3s0f1 && nmcli con start enp3s0f1
# nmcli con down bond0 && nmcli con start bond0

systemctl restart network

EOF

cat > /root/nic.restore.sh << 'EOF'
#!/bin/bash

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete uuid ${i} ; done 

# re-create primary connection 
nmcli con add type ethernet \
    con-name enp3s0f0 \
    ifname enp3s0f0 \
    ipv4.method 'manual' \
    ipv4.address '39.137.101.28/25' \
    ipv4.gateway '39.137.101.126' \
    ipv4.dns '117.177.241.16'

# restart interface
# nmcli con down enp3s0f0 && nmcli con up enp3s0f0

systemctl restart network

exit 0
EOF

chmod +x /root/nic.restore.sh

cat > ~/cron-network-con-recreate << EOF
*/2 * * * * /bin/bash /root/nic.restore.sh
EOF

crontab ~/cron-network-con-recreate

bash /root/nic.bond.sh

```

### worker-0 disk
```bash

#########################################
# ssd cache + hdd
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/logical_volume_manager_administration/index#lvm_cache_volume_creation
umount /data
lsblk -d -o name,rota

lvremove  /dev/datavg/datalv

pvcreate /dev/nvme0n1

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/vg_grow
vgextend datavg /dev/nvme0n1

## raid5 + cache
lvcreate --type raid5 -L 1G --stripes 9 -n hddlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

lvcreate --type raid5 -L 3.8T --stripes 9 -n mixlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

lvcreate -L 1G -n ssdlv datavg /dev/nvme0n1

# lvcreate --type cache-pool -L 300G -n cache1 datavg /dev/nvme0n1

lvcreate -L 1.4T -n cache1 datavg /dev/nvme0n1

lvcreate -L 14G -n cache1meta datavg /dev/nvme0n1

lvconvert --type cache-pool --poolmetadata datavg/cache1meta datavg/cache1

lvconvert --type cache --cachepool datavg/cache1 datavg/mixlv

# lvcreate --type raid5 --stripes 9 -L 1T -I 16M -R 4096K -n hddlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

# lvcreate --type raid5 --stripes 9 -L 1T -I 16M -R 4096K -n datalv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

# lvcreate --type raid5 --stripes 9 -L 1T -n datalv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

## raid0 + cache

lvcreate --type raid0 -L 4T --stripes 10 -n hddlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk










lvcreate --type raid0 -L 1T --stripes 10 -n mixlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

lvcreate -L 300G -n ssdlv datavg /dev/nvme0n1

lvcreate --type cache-pool -L 300G -n cpool datavg /dev/nvme0n1

lvs -a -o name,size,attr,devices datavg

# lvconvert --type cache --cachepool cpool datavg/datalv

lvconvert --type cache --cachepool cpool datavg/mixlv

# lvconvert --type cache --cachepool cpool --cachemode writeback datavg/datalv

# lvs -a -o name,size,attr,devices datavg
# lvs -o+cache_mode datavg

# mkfs.xfs /dev/datavg/datalv
mkfs.xfs /dev/datavg/hddlv
mkfs.xfs /dev/datavg/ssdlv
mkfs.xfs /dev/datavg/mixlv

mkdir -p /data/
mkdir -p /data_ssd/
mkdir -p /data_mix/

cat /etc/fstab

cat << EOF >> /etc/fstab
/dev/datavg/hddlv /data                  xfs     defaults        0 0
/dev/datavg/ssdlv /data_ssd                  xfs     defaults        0 0
/dev/datavg/mixlv /data_mix                  xfs     defaults        0 0
EOF

mount -a
df -h | grep \/data

# cleanup
umount /data/
umount /data_ssd/
umount /data_mix/
lvremove -f /dev/datavg/hddlv
lvremove -f /dev/datavg/ssdlv
lvremove -f /dev/datavg/mixlv

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --directory=./ --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --directory=./ --ioengine=sync --size=100g 

blktrace /dev/datavg/mixlv /dev/nvme0n1 /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

blkparse -o /dev/null -i dm-42 -d dm-42.bin
btt -i dm-42.blktrace.bin

blkparse -o /dev/null -i nvme0n1 -d nvme0n1.bin
btt -i nvme0n1.bin | less

blkparse -o /dev/null -i sdb -d sdb.bin
btt -i sdb.bin | less


dstat -D /dev/mapper/datavg-hddlv,sdd,nvme0n1 -N enp3s0f0

dstat -D /dev/mapper/datavg-hddlv,sdd,nvme0n1 --disk-util 

bmon -p ens8f0,ens8f1,enp3s0f0,enp3s0f1

lvs -o+lv_all datavg/mixlv_corig

lvs -o+Layout datavg/mixlv_corig

lvs -o+CacheReadHits,CacheReadMisses

lvs -o+Layout

blockdev --report 
# https://access.redhat.com/solutions/3588841
/sbin/blockdev --setra 262144 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 8192 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 0 /dev/mapper/datavg-hddlv


hdparm -t /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 4096 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 8192 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 16384 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 32768 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 65536 /dev/mapper/datavg-hddlv
/sbin/blockdev --setra 131072 /dev/mapper/datavg-hddlv

for f in /dev/mapper/datavg-hddlv_rimage_*; do /sbin/blockdev --setra 65536 $f ; done

for f in /dev/mapper/datavg-hddlv_rimage_*; do /sbin/blockdev --setra 131072 $f ; done

blktrace /dev/datavg/hddlv /dev/nvme0n1 /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

# Generate distribution of file sizes from the command prompt
# https://superuser.com/questions/565443/generate-distribution-of-file-sizes-from-the-command-prompt
find /data/mnt/ -type f > list
cat list | xargs ls -l > list.size
cat list.size | awk '{ n=int(log($5)/log(2));                         \
          if (n<10) n=10;                                               \
          size[n]++ }                                                   \
      END { for (i in size) printf("%d %d\n", 2^i, size[i]) }'          \
 | sort -n                                                              \
 | awk 'function human(x) { x[1]/=1024;                                 \
                            if (x[1]>=1024) { x[2]++;                   \
                                              human(x) } }              \
        { a[1]=$1;                                                      \
          a[2]=0;                                                       \
          human(a);                                                     \
          printf("%3d%s: %6d\n", a[1],substr("kMGTEPYZ",a[2]+1,1),$2) }' 
#   1k:      2
#  16k: 18875840
#  64k: 7393088
# 128k: 5093147
# 512k: 1968632
#   1M: 914486

cat list.size | awk '{size[int(log($5)/log(2))]++}END{for (i in size) printf("%10d %3d\n", 2^i, size[i])}' | sort -n

# 5.5
var_basedir="/data_ssd/mnt"
find $var_basedir -type f -size -16k  > list.16k
find $var_basedir -type f -size -128k  -size +16k > list.128k
find $var_basedir -type f -size +128k > list.+128k
find $var_basedir -type f > list


dstat --output /root/dstat.csv -D /dev/mapper/datavg-mixlv,/dev/mapper/datavg-mixlv_corig,sdh,sdab -N bond0

dstat -D /dev/mapper/datavg-hddlv,/dev/datavg/ext4lv,sdh,sdab -N bond0

i=0
while read f; do
  /bin/cp -f $f /data_mix/mnt/$i
  ((i++))
done < list

find /data_mix/mnt/ -type f > list

cat list | shuf > list.shuf.all

cat list.16k | shuf > list.shuf.16k
cat list.128k | shuf > list.shuf.128k
cat list.+128k | shuf > list.shuf.+128k
cat list.128k list.+128k | shuf > list.shuf.+16k

# zte use 1800
var_total=10
rm -f split.list.*


split -n l/$var_total list.shuf.all split.list.all.

split -n l/$var_total list.shuf.16k split.list.16k.
split -n l/$var_total list.shuf.128k split.list.128k.
split -n l/$var_total list.shuf.+128k split.list.+128k.
split -n l/$var_total list.shuf.+16k split.list.+16k.


for f in split.list.16k.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
# for f in split.list.+16k.*; do 
#     cat $f | xargs -I DEMO cat DEMO > /dev/null &
# done
for f in split.list.128k.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
for f in split.list.+128k.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

for f in split.list.all.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

ps -ef | grep /data_ssd/mnt | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO

echo "wait to finish"
wait
# while true; do
#   for f in split.list.all.*; do 
#       cat $f | xargs -I DEMO cat DEMO > /dev/null &
#   done
#   echo "wait to finish"
#   wait
# done
kill -9 $(jobs -p)

jobs -p  | xargs kill

ps -ef | grep /mnt/zxdfs | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO

ps -ef | grep /data_mix/mnt | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO




```

### worker-1 host

```bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum --disableplugin=subscription-manager  repolist

yum install -y byobu htop iostat

yum -y update

hostnamectl set-hostname worker-2.ocpsc.redhat.ren

nmcli connection modify eno1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up eno1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 5.5 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk
lsblk | grep 5.5 | awk '{print $1}' | wc -l
# 24

yum install -y lvm2

pvcreate -y /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

vgcreate datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

vgs

lvcreate --type raid0 -l 100%FREE --stripes 24 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                  xfs     defaults        0 0

EOF

mount -a

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk 5
iostat -m -x dm-10 5


########################################
# ntp
yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

systemctl disable --now firewalld.service

# setup time server
/bin/cp -f /etc/chrony.conf /etc/chrony.conf.bak

cat << EOF > /etc/chrony.conf
server 117.177.241.16 iburst
server 0.rhel.pool.ntp.org iburst
server 1.rhel.pool.ntp.org iburst
server 2.rhel.pool.ntp.org iburst
server 3.rhel.pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
chronyc sources -v

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking

```

### worker-1 disk
```bash
##################################
## config
mkdir -p /app_conf/zxcdn


#########################################
# ssd cache + hdd
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/logical_volume_manager_administration/index#lvm_cache_volume_creation
umount /data
lsblk -d -o name,rota

lvremove  /dev/datavg/datalv

# lsblk | grep 894 | awk '{print $1}'

pvcreate /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/vg_grow
vgextend datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

## raid5

lvcreate --type raid5 -L 3T --stripes 23 -n hddlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 1G --stripes 10 -n ssdlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid5 -L 3T --stripes 23 -n mixlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 1T --stripes 9 -n cache1 datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid5 -L 10G --stripes 9 -n cache1meta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cache1meta datavg/cache1

lvconvert --type cache --cachepool datavg/cache1 datavg/mixlv

# lvcreate --type raid5 --stripes 9 -L 1T -I 16M -R 4096K -n hddlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk



lvcreate --type raid5 -L 12T --stripes 23 -n mix0lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 4T --stripes 10 -n cachemix0 datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 40G --stripes 10 -n cachemix0meta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cachemix0meta datavg/cachemix0

lvconvert --type cache --cachepool datavg/cachemix0 datavg/mix0lv


lvcreate --type raid5 -L 1T --stripes 23 -n mix0weblv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 162G --stripes 10 -n cachemix0web datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 2G --stripes 10 -n cachemix0webmeta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cachemix0webmeta datavg/cachemix0web

lvconvert --type cache --cachepool datavg/cachemix0web datavg/mix0weblv


# lvcreate --type raid0 -L 200G --stripes 10 -n ssd0lv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 200G --stripes 4 -n ssd0lv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/ssd0lv

## raid0 + stripe

lvcreate --type raid0 -L 130T --stripes 24 -n hddlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx







lvcreate --type raid0 -L 900G --stripesize 128k --stripes 24 -n testfslv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

mkfs.ext4 /dev/datavg/testfslv
mount /dev/datavg/testfslv /data_mix






lvcreate --type raid0 -L 5T --stripes 10 -n ssdlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid5 -L 5T --stripes 9 -n ssdlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

mkfs.ext4 /dev/datavg/ssdlv
mount /dev/datavg/ssdlv /data_ssd

rsync -e ssh --info=progress2 -P --delete -ar --files-from=list.20k / 39.134.201.65:/data_ssd/mnt/

rsync -e ssh --info=progress2 -P --delete -ar /data/mnt/ 39.134.201.65:/data_ssd/mnt/

rsync -e ssh --info=progress2 -P --delete -ar /data/mnt/zxdfs/webcache-011/   39.134.201.65:/data_ssd/mnt/zxdfs/webcache-011/

rsync -e ssh --info=progress2 -P --delete -ar /data/mnt/zxdfs/webcache-012/   39.134.201.65:/data_ssd/mnt/zxdfs/webcache-012/







# slow
lvcreate --type raid0 -L 400G --stripesize 128k --stripes 12 -n testfslv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl 

# Generate distribution of file sizes from the command prompt
# https://superuser.com/questions/565443/generate-distribution-of-file-sizes-from-the-command-prompt
cat list | xargs ls -l > list.size
cat list.size | awk '{ n=int(log($5)/log(2));                         \
          if (n<10) n=10;                                               \
          size[n]++ }                                                   \
      END { for (i in size) printf("%d %d\n", 2^i, size[i]) }'          \
 | sort -n                                                              \
 | awk 'function human(x) { x[1]/=1024;                                 \
                            if (x[1]>=1024) { x[2]++;                   \
                                              human(x) } }              \
        { a[1]=$1;                                                      \
          a[2]=0;                                                       \
          human(a);                                                     \
          printf("%3d%s: %6d\n", a[1],substr("kMGTEPYZ",a[2]+1,1),$2) }' 




lvcreate --type raid0 -L 1T --stripes 24 -n mixlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 300G --stripes 10 -n ssdlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 300G --stripes 10 -n cache1 datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 3G --stripes 10 -n cache1meta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cache1meta datavg/cache1

# lvs -a -o name,size,attr,devices datavg

lvconvert --type cache --cachepool datavg/cache1 datavg/mixlv

# lvs -a -o name,size,attr,devices datavg
# lvs -o+cache_mode datavg

mkfs.xfs /dev/datavg/hddlv
mkfs.xfs /dev/datavg/ssdlv
mkfs.xfs /dev/datavg/mixlv
mkfs.xfs /dev/datavg/mix0lv
mkfs.xfs /dev/datavg/mix0weblv

mkdir -p /data/
mkdir -p /data_ssd/
mkdir -p /data_mix/
mkdir -p /data_mix0
mkdir -p /data_mix0_web/

cat /etc/fstab

cat << EOF >> /etc/fstab
/dev/datavg/hddlv /data                  xfs     defaults        0 0
# /dev/datavg/ssdlv /data_ssd                  xfs     defaults        0 0
# /dev/datavg/mixlv /data_mix                  xfs     defaults        0 0
# /dev/datavg/mix0lv  /data_mix0                  xfs     defaults        0 0
# /dev/datavg/mix0weblv  /data_mix0_web                  xfs     defaults        0 0
EOF

mount -a
df -h | grep \/data

dd if=/dev/zero of=/data/testfile bs=4k count=9999 oflag=dsync
dd if=/dev/zero of=/data_ssd/testfile bs=4k count=9999 oflag=dsync
dd if=/dev/zero of=/data_mix/testfile bs=4k count=9999 oflag=dsync

dd if=/dev/zero of=/data/testfile bs=4M count=9999 oflag=dsync
dd if=/dev/zero of=/data_ssd/testfile bs=4M count=9999 oflag=dsync
dd if=/dev/zero of=/data_mix/testfile bs=4M count=9999 oflag=dsync

dd if=/data/testfile of=/dev/null bs=4k count=9999 oflag=dsync
dd if=/data_ssd/testfile of=/dev/null bs=4k count=9999 oflag=dsync
dd if=/data_mix/testfile of=/dev/null bs=4k count=9999 oflag=dsync

dd if=/dev/zero of=/data/testfile.large bs=4M count=9999 oflag=direct
dd if=/dev/zero of=/data_ssd/testfile.large bs=4M count=9999 oflag=direct
dd if=/dev/zero of=/data_mix/testfile.large bs=4M count=9999 oflag=direct

dd if=/dev/zero of=/data/testfile.large bs=4M count=9999
dd if=/dev/zero of=/data_ssd/testfile.large bs=4M count=9999 
dd if=/dev/zero of=/data_mix/testfile.large bs=4M count=9999 

dd if=/data/testfile.large of=/dev/null bs=4k count=9999 oflag=dsync
dd if=/data_ssd/testfile.large of=/dev/null bs=4k count=9999 oflag=dsync
dd if=/data_mix/testfile.large of=/dev/null bs=4k count=9999 oflag=dsync

dd if=/data/testfile.large of=/dev/null bs=4M count=9999 oflag=dsync
dd if=/data_ssd/testfile.large of=/dev/null bs=4M count=9999 oflag=dsync
dd if=/data_mix/testfile.large of=/dev/null bs=4M count=9999 oflag=dsync

dd if=/data/testfile.large of=/dev/null bs=4M count=9999
dd if=/data_ssd/testfile.large of=/dev/null bs=4M count=9999
dd if=/data_mix/testfile.large of=/dev/null bs=4M count=9999

dd if=/data/testfile.large of=/dev/null bs=40M count=9999
dd if=/data_ssd/testfile.large of=/dev/null bs=40M count=9999
dd if=/data_mix/testfile.large of=/dev/null bs=40M count=9999

# cleanup
umount /data/
umount /data_ssd/
umount /data_mix/
umount /data_mix0/
lvremove -f /dev/datavg/hddlv
lvremove -f /dev/datavg/ssdlv
lvremove -f /dev/datavg/mixlv
lvremove -f /dev/datavg/mix0lv

# ssd tunning
# https://serverfault.com/questions/80134/linux-md-vs-lvm-performance
hdparm -tT /dev/md0

# https://www.ibm.com/developerworks/cn/linux/l-lo-io-scheduler-optimize-performance/index.html
cat /sys/block/*/queue/scheduler

lsblk | grep 894 | awk '{print $1}' | xargs -I DEMO cat /sys/block/DEMO/queue/scheduler

lsblk | grep 894 | awk '{print "echo deadline > /sys/block/"$1"/queue/scheduler"}' 

iostat -x -m 3 /dev/mapper/datavg-mix0weblv /dev/mapper/datavg-mix0weblv_corig /dev/mapper/datavg-cachemix0web_cdata /dev/mapper/datavg-cachemix0web_cmeta


dstat -D /dev/mapper/datavg-hddlv,sdh,sdab -N bond0

dstat -D /dev/mapper/datavg-hddlv,sdh,sdab --disk-util 

bmon -p eno1,eno2,ens2f0,ens2f1,bond0

lvs -o+lv_all datavg/mixlv_corig

lvs -o+Layout datavg/mixlv_corig

lvs -o+CacheReadHits,CacheReadMisses

lvs -o+Layout

blockdev --report 
# https://access.redhat.com/solutions/3588841
/sbin/blockdev --setra 1048576 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 524288 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 262144 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 131072 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 65536 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 32768 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 16384 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 8192 /dev/mapper/datavg-hddlv

/sbin/blockdev --setra 8192 /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx


for f in /dev/mapper/datavg-hddlv_rimage_*; do /sbin/blockdev --setra 8192 $f ; done

for f in /dev/mapper/datavg-hddlv_rimage_*; do /sbin/blockdev --setra 16384 $f ; done

blktrace /dev/datavg/hddlv  /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

blkparse -o /dev/null -i dm-24 -d dm-24.bin
btt -i dm-24.bin | less

blkparse -o /dev/null -i sda -d sda.bin
btt -i sda.bin | less


# 5.5
# find /data/mnt/ -type f -size -2M -size +512k  > list
var_basedir="/data_mix/mnt"
find $var_basedir -type f -size -2M  > list.2m
find $var_basedir -type f -size -10M  -size +2M > list.10m
find $var_basedir -type f -size +10M > list.100m

find /data/mnt/ -type f > list
dstat --output /root/dstat.csv -D /dev/mapper/datavg-mixlv,/dev/mapper/datavg-mixlv_corig,sdh,sdab -N bond0

dstat -D /dev/mapper/datavg-hddlv,/dev/datavg/testfslv,sdh,sdab -N bond0

mkdir -p /data_mix/mnt
i=11265199
while read f; do
  /bin/cp -f $f /data_mix/mnt/$i &
  ((i++))
  if (( $i % 200 == 0 )) ; then
    wait
  fi
done < list.100m

while true; do
  df -h | grep /data
  sleep 60
done

find /data_mix/mnt/ -type f > list

cat list | shuf > list.shuf.all

cat list.2m | shuf > list.shuf.2m
cat list.10m | shuf > list.shuf.10m
cat list.100m | shuf > list.shuf.100m
cat list.10m list.100m | shuf > list.shuf.+2m

# zte use 1800
var_total=10
split -n l/$var_total list.shuf.all split.list.all.
split -n l/$var_total list.shuf.2m split.list.2m.
split -n l/$var_total list.shuf.10m split.list.10m.
split -n l/$var_total list.shuf.100m split.list.100m.
split -n l/$var_total list.shuf.+2m split.list.+2m.

rm -f split.list.*

for f in split.list.2m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
# for f in split.list.+2m.*; do 
#     cat $f | xargs -I DEMO cat DEMO > /dev/null &
# done
for f in split.list.10m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
for f in split.list.100m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

for f in split.list.all.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

jobs -p | xargs kill


ps -ef | grep xargs | grep DEMO | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO

ps -ef | grep /data_mix/mnt | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO


rclone sync /data/mnt/ /data/backup/mnt/ -P -L --transfers 64
rclone sync /data/home/ /data/backup/home/ -P -L --transfers 64
rclone sync /data/ztecdn/ /data/backup/ztecdn/ -P -L --transfers 64

rclone sync /data/backup/mnt/ /data/mnt/ -P -L --transfers 64


# check sn
dmidecode -t 1
# # dmidecode 3.2
# Getting SMBIOS data from sysfs.
# SMBIOS 3.0.0 present.

# Handle 0x0001, DMI type 1, 27 bytes
# System Information
#         Manufacturer: Huawei
#         Product Name: 5288 V5
#         Version: Purley
#         Serial Number: 2102312CJSN0K9000028
#         UUID: a659bd21-cc64-83c1-e911-6cd6de4f8050
#         Wake-up Type: Power Switch
#         SKU Number: Purley
#         Family: Purley

# check disk
lshw -c disk
  # *-disk:0
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.2.0
  #      bus info: scsi@0:0.2.0
  #      logical name: /dev/sda
  #      version: T010
  #      serial: xLkuQ2-XVVp-sfs3-8Rgm-vRgS-uysW-ncIudq
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:1
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.3.0
  #      bus info: scsi@0:0.3.0
  #      logical name: /dev/sdb
  #      version: T010
  #      serial: 5d2geD-fGih-Q6yK-2xVs-lWUG-tH38-qQWRC6
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:2
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.c.0
  #      bus info: scsi@0:0.12.0
  #      logical name: /dev/sdk
  #      version: T010
  #      serial: fePKOb-MTZv-j4Xz-qNjo-cPTr-078I-vZYiPH
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:3
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.d.0
  #      bus info: scsi@0:0.13.0
  #      logical name: /dev/sdl
  #      version: T010
  #      serial: fUTBJp-fXg0-0uJX-V4Qp-vSfZ-yxmb-G8LNam
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:4
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.e.0
  #      bus info: scsi@0:0.14.0
  #      logical name: /dev/sdm
  #      version: T010
  #      serial: SNfxce-ytX2-7j4p-opnQ-lOxC-AFIp-VbCfec
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:5
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.f.0
  #      bus info: scsi@0:0.15.0
  #      logical name: /dev/sdn
  #      version: T010
  #      serial: HJqH2G-XT7i-2R27-dSb0-q36n-T4Ut-Ml4GiE
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:6
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.10.0
  #      bus info: scsi@0:0.16.0
  #      logical name: /dev/sdo
  #      version: T010
  #      serial: IBh87y-SOWJ-rI3R-Mshu-agWM-TyHs-6ko0iu
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:7
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.11.0
  #      bus info: scsi@0:0.17.0
  #      logical name: /dev/sdp
  #      version: T010
  #      serial: erBKxc-gBsD-msEq-aXMJ-8akE-FGRb-SjBk1w
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:8
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.12.0
  #      bus info: scsi@0:0.18.0
  #      logical name: /dev/sdq
  #      version: T010
  #      serial: HsiL2h-6736-4x4H-0OTz-HuXj-My1c-RRShQP
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:9
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.13.0
  #      bus info: scsi@0:0.19.0
  #      logical name: /dev/sdr
  #      version: T010
  #      serial: yZQ8MH-7SCw-KIFL-fphN-S0W0-GS4V-Wc2gwx
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:10
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.14.0
  #      bus info: scsi@0:0.20.0
  #      logical name: /dev/sds
  #      version: T010
  #      serial: pp6xvN-MBT9-aLkB-65hF-7fwE-29vt-hA51K9
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:11
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.15.0
  #      bus info: scsi@0:0.21.0
  #      logical name: /dev/sdt
  #      version: T010
  #      serial: jXj3cL-qvoJ-JWP0-jvp9-WEbn-yD63-e6vFmP
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:12
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.4.0
  #      bus info: scsi@0:0.4.0
  #      logical name: /dev/sdc
  #      version: T010
  #      serial: Ca6Nyo-Oq5p-UdAY-oqIs-DlK5-1PPy-ugvF3P
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:13
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.16.0
  #      bus info: scsi@0:0.22.0
  #      logical name: /dev/sdu
  #      version: T010
  #      serial: GOTXh2-34fo-rZfh-IB5d-RkwW-o5EC-rDD4R1
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:14
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.17.0
  #      bus info: scsi@0:0.23.0
  #      logical name: /dev/sdv
  #      version: T010
  #      serial: 7Yn8xd-68Xu-A0RC-nx5Q-YEvJ-QPEG-CwjkP0
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:15
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.18.0
  #      bus info: scsi@0:0.24.0
  #      logical name: /dev/sdw
  #      version: T010
  #      serial: hdz5tv-f2Zm-wuf8-qtKO-XIlN-4Z1E-uHapKc
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:16
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.19.0
  #      bus info: scsi@0:0.25.0
  #      logical name: /dev/sdx
  #      version: T010
  #      serial: C3VFhO-mh9a-vKIR-Gi1o-pc05-LOqY-oErH8r
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:17
  #      description: SCSI Disk
  #      product: HW-SAS3408
  #      vendor: AVAGO
  #      physical id: 2.0.0
  #      bus info: scsi@0:2.0.0
  #      logical name: /dev/sdy
  #      version: 5.06
  #      serial: 00457f537b174eb025007018406c778a
  #      size: 446GiB (478GB)
  #      capabilities: gpt-1.00 partitioned partitioned:gpt
  #      configuration: ansiversion=5 guid=f72b8f56-6e5d-4a0c-a2a0-bf641ac2c2ff logicalsectorsize=512 sectorsize=4096
  # *-disk:18
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.5.0
  #      bus info: scsi@0:0.5.0
  #      logical name: /dev/sdd
  #      version: T010
  #      serial: 1sulWQ-pttz-zf0P-WTEe-cydl-lY6Q-CdX4Hv
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:19
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.6.0
  #      bus info: scsi@0:0.6.0
  #      logical name: /dev/sde
  #      version: T010
  #      serial: JF6q37-XaYh-qoXg-mPeZ-4Ofr-Qrkt-nh21RR
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:20
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.7.0
  #      bus info: scsi@0:0.7.0
  #      logical name: /dev/sdf
  #      version: T010
  #      serial: vvF48a-k1sq-7v1m-dpSh-yb50-KLLk-otk7lA
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:21
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.8.0
  #      bus info: scsi@0:0.8.0
  #      logical name: /dev/sdg
  #      version: T010
  #      serial: NHU0VX-vm31-DyRP-V4dc-gx7T-dXGI-Bb8qlw
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:22
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.9.0
  #      bus info: scsi@0:0.9.0
  #      logical name: /dev/sdh
  #      version: T010
  #      serial: jCIRNL-K08S-oYZc-Q5Eb-Y2ht-0NYt-0luz1T
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:23
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.a.0
  #      bus info: scsi@0:0.10.0
  #      logical name: /dev/sdi
  #      version: T010
  #      serial: wiQiLJ-Arua-8vcg-m6ta-KgSL-f1kD-rgzKxD
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:24
  #      description: ATA Disk
  #      product: HUS726T6TALE600
  #      physical id: 0.b.0
  #      bus info: scsi@0:0.11.0
  #      logical name: /dev/sdj
  #      version: T010
  #      serial: T7vZ96-uTGr-tvFz-jKoZ-479j-vRvh-WeCVRJ
  #      size: 5589GiB (6001GB)
  #      capacity: 5589GiB (6001GB)
  #      capabilities: 7200rpm lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:0
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.e.0
  #      bus info: scsi@15:0.14.0
  #      logical name: /dev/sdz
  #      version: M030
  #      serial: HE21uM-4KRw-heFX-IFVf-zO8Y-Rzah-ncwlwL
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:1
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.f.0
  #      bus info: scsi@15:0.15.0
  #      logical name: /dev/sdaa
  #      version: M030
  #      serial: RGeqtd-dTEc-hV8g-Xd9o-I1Ke-sDH1-UK6mZg
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:2
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.10.0
  #      bus info: scsi@15:0.16.0
  #      logical name: /dev/sdab
  #      version: M030
  #      serial: 1ROsNp-0J4j-DuWM-1nNl-Fo3K-gWfg-d7VDLq
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:3
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.11.0
  #      bus info: scsi@15:0.17.0
  #      logical name: /dev/sdac
  #      version: M030
  #      serial: s0XeSI-Zl3B-0xcU-8wi3-BvVo-vU3k-cLZx22
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:4
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.12.0
  #      bus info: scsi@15:0.18.0
  #      logical name: /dev/sdad
  #      version: M030
  #      serial: rZZ7yM-KImV-6Ld8-xmOJ-KyiC-Wstp-4t35S3
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:5
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.13.0
  #      bus info: scsi@15:0.19.0
  #      logical name: /dev/sdae
  #      version: M030
  #      serial: LI50dd-vn2G-RiYE-5iuL-nxYI-TXCT-zs1lSY
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:6
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.14.0
  #      bus info: scsi@15:0.20.0
  #      logical name: /dev/sdaf
  #      version: M030
  #      serial: 2hkDxG-90a2-mkEJ-GxmQ-doAv-SPT1-8qyo10
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:7
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.15.0
  #      bus info: scsi@15:0.21.0
  #      logical name: /dev/sdag
  #      version: M030
  #      serial: bMQrTa-IKF7-vDFU-5RSR-cj4a-cOUL-QAY2yI
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:8
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.16.0
  #      bus info: scsi@15:0.22.0
  #      logical name: /dev/sdah
  #      version: M030
  #      serial: q0VZpE-4sub-HKbe-RkRx-G0wM-HOeU-NDRXRe
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:9
  #      description: ATA Disk
  #      product: MTFDDAK960TDC-1A
  #      physical id: 0.17.0
  #      bus info: scsi@15:0.23.0
  #      logical name: /dev/sdai
  #      version: M030
  #      serial: fEj7Rr-FSS8-ruwb-IjSj-xW6l-oj6v-q1pSNV
  #      size: 894GiB (960GB)
  #      capacity: 894GiB (960GB)
  #      capabilities: lvm2
  #      configuration: ansiversion=6 logicalsectorsize=512 sectorsize=4096
  # *-disk:10
  #      description: SCSI Disk
  #      product: HW-SAS3408
  #      vendor: AVAGO
  #      physical id: 2.0.0
  #      bus info: scsi@15:2.0.0
  #      logical name: /dev/sdaj
  #      version: 5.06
  #      serial: 00a6b489499e4cb02500904af3624ac6
  #      size: 893GiB (958GB)
  #      capabilities: partitioned partitioned:dos
  #      configuration: ansiversion=5 logicalsectorsize=512 sectorsize=4096 signature=550d3974

yum -y install fio

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/vdo-ev-performance-testing

lvs -o+cache_policy,cache_settings,chunksize datavg/mix0weblv

# https://access.redhat.com/solutions/2961861
for i in  /proc/[0-9]* ; do echo $i >> /tmp/mountinfo ;  grep -q "/dev/mapper/datavg-mix0weblv" $i/mountinfo ; echo $? >> /tmp/mountinfo ; done

grep -B 1 '^0$' /tmp/mountinfo 

lvcreate --type raid5 -L 120G --stripes 23 -n mixtestlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/mixtestlv
# Run status group 0 (all jobs):
#    READ: bw=587MiB/s (615MB/s), 587MiB/s-587MiB/s (615MB/s-615MB/s), io=79.9GiB (85.8GB), run=139473-139473msec
#   WRITE: bw=147MiB/s (155MB/s), 147MiB/s-147MiB/s (155MB/s-155MB/s), io=20.1GiB (21.6GB), run=139473-139473msec

lvcreate --type raid6 -L 120G --stripes 22 -n mixtestlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/mixtestlv
# Run status group 0 (all jobs):
#    READ: bw=586MiB/s (614MB/s), 586MiB/s-586MiB/s (614MB/s-614MB/s), io=79.9GiB (85.8GB), run=139739-139739msec
#   WRITE: bw=147MiB/s (154MB/s), 147MiB/s-147MiB/s (154MB/s-154MB/s), io=20.1GiB (21.6GB), run=139739-139739msec

lvcreate --type raid0 -L 120G --stripes 24 -n mixtestlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/mixtestlv
# Run status group 0 (all jobs):
#    READ: bw=1139MiB/s (1194MB/s), 1139MiB/s-1139MiB/s (1194MB/s-1194MB/s), io=79.9GiB (85.8GB), run=71841-71841msec
#   WRITE: bw=286MiB/s (300MB/s), 286MiB/s-286MiB/s (300MB/s-300MB/s), io=20.1GiB (21.6GB), run=71841-71841msec

lvcreate --type raid0 -L 100G --stripes 10 -n mixtestlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/mixtestlv
# Run status group 0 (all jobs):
#    READ: bw=1358MiB/s (1424MB/s), 1358MiB/s-1358MiB/s (1424MB/s-1424MB/s), io=79.9GiB (85.8GB), run=60282-60282msec
#   WRITE: bw=341MiB/s (358MB/s), 341MiB/s-341MiB/s (358MB/s-358MB/s), io=20.1GiB (21.6GB), run=60282-60282msec


lvcreate --type raid5 -L 100G --stripes 9 -n mixtestlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/mixtestlv



lvcreate --type raid6 -L 100G --stripes 9 -n mixtestlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

lvremove -f datavg/mixtestlv



lvcreate --type raid5 -L 120G --stripes 23 -n mixtestlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 40G --stripes 10 -n cachetest datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 400M --stripes 10 -n cachetestmeta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cachetestmeta datavg/cachetest

lvconvert --type cache --cachepool datavg/cachetest datavg/mixtestlv

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g -random_distribution=zoned:60/10:30/20:8/30:2/40

lvremove -f datavg/mixtestlv
# Run status group 0 (all jobs):
#    READ: bw=716MiB/s (750MB/s), 716MiB/s-716MiB/s (750MB/s-750MB/s), io=31.0GiB (34.3GB), run=45744-45744msec
#   WRITE: bw=180MiB/s (189MB/s), 180MiB/s-180MiB/s (189MB/s-189MB/s), io=8228MiB (8628MB), run=45744-45744msec

lvcreate --type raid5 -L 120G --stripes 23 -n mixtestlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 40G --stripes 9 -n cachetest datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid5 -L 400M --stripes 9 -n cachetestmeta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cachetestmeta datavg/cachetest

lvconvert --type cache --cachepool datavg/cachetest datavg/mixtestlv

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g -random_distribution=zoned:60/10:30/20:8/30:2/40

lvremove -f datavg/mixtestlv
# Run status group 0 (all jobs):
#    READ: bw=487MiB/s (511MB/s), 487MiB/s-487MiB/s (511MB/s-511MB/s), io=79.9GiB (85.8GB), run=167880-167880msec
#   WRITE: bw=122MiB/s (128MB/s), 122MiB/s-122MiB/s (128MB/s-128MB/s), io=20.1GiB (21.6GB), run=167880-167880msec

lvcreate -L 100G -n singledisklv datavg /dev/sda

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/singledisklv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g -random_distribution=zoned:60/10:30/20:8/30:2/40

lvremove -f datavg/singledisklv
# Run status group 0 (all jobs):
#    READ: bw=151MiB/s (158MB/s), 151MiB/s-151MiB/s (158MB/s-158MB/s), io=44.2GiB (47.5GB), run=300031-300031msec
#   WRITE: bw=37.0MiB/s (39.8MB/s), 37.0MiB/s-37.0MiB/s (39.8MB/s-39.8MB/s), io=11.1GiB (11.9GB), run=300031-300031msec

lvcreate -L 20G -n singledisklv datavg /dev/sdai

fio --rw=rw --rwmixread=80 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/singledisklv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=20g -random_distribution=zoned:60/10:30/20:8/30:2/40

lvremove -f datavg/singledisklv
# Run status group 0 (all jobs):
#    READ: bw=431MiB/s (452MB/s), 431MiB/s-431MiB/s (452MB/s-452MB/s), io=16.0GiB (17.2GB), run=38005-38005msec
#   WRITE: bw=108MiB/s (113MB/s), 108MiB/s-108MiB/s (113MB/s-113MB/s), io=4088MiB (4287MB), run=38005-38005msec

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --directory=./ --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --directory=./ --ioengine=sync --size=100g 

blktrace /dev/datavg/mixlv 
# http benchmark tools
yum install httpd-tools
# https://github.com/philipgloyne/apachebench-for-multi-url
# https://hub.docker.com/r/chrisipa/ab-multi-url
# https://www.simonholywell.com/post/2015/06/parallel-benchmark-many-urls-with-apachebench/


fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g

fio --rw=rw --rwmixread=99 --bsrange=128k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g



```

### worker-1 nic bond

```bash
ip link show
# 2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bd:24 brd ff:ff:ff:ff:ff:ff
# 3: eno2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bd:25 brd ff:ff:ff:ff:ff:ff
# 4: ens2f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether 08:4f:0a:b5:a2:be brd ff:ff:ff:ff:ff:ff
# 5: eno3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bd:26 brd ff:ff:ff:ff:ff:ff
# 6: eno4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bd:27 brd ff:ff:ff:ff:ff:ff
# 7: ens2f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether 08:4f:0a:b5:a2:bf brd ff:ff:ff:ff:ff:ff

ip a s eno1
# 2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
#     link/ether cc:64:a6:59:bd:24 brd ff:ff:ff:ff:ff:ff
#     inet 39.134.201.65/27 brd 39.134.201.95 scope global noprefixroute eno1
#        valid_lft forever preferred_lft forever
#     inet6 fe80::149f:d0ce:2700:4bf2/64 scope link noprefixroute
#        valid_lft forever preferred_lft forever

ethtool eno1  # 10000baseT/Full
ethtool eno2  # 10000baseT/Full
ethtool eno3  # 1000baseT/Full
ethtool eno4  # 1000baseT/Full
ethtool ens2f0  #  10000baseT/Full
ethtool ens2f1  #  10000baseT/Full

nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad 

nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3
    
nmcli con add type bond-slave ifname eno2 con-name eno2 master bond0
nmcli con add type bond-slave ifname ens2f0 con-name ens2f0 master bond0
nmcli con add type bond-slave ifname ens2f1 con-name ens2f1 master bond0

nmcli con down eno2
nmcli con up eno2
nmcli con down ens2f0
nmcli con up ens2f0
nmcli con down ens2f1
nmcli con up ens2f1
nmcli con down bond0
nmcli con start bond0       


#######################################
# nic bond
cat > /root/nic.bond.sh << 'EOF'
#!/bin/bash

set -x 

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete  ${i} ; done 

nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad \
    ipv4.method 'manual' \
    ipv4.address '39.134.201.65/27' \
    ipv4.gateway '39.134.201.94' \
    ipv4.dns '117.177.241.16'
    
nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3

nmcli con add type bond-slave ifname eno1 con-name eno1 master bond0    
nmcli con add type bond-slave ifname eno2 con-name eno2 master bond0
nmcli con add type bond-slave ifname ens2f0 con-name ens2f0 master bond0
nmcli con add type bond-slave ifname ens2f1 con-name ens2f1 master bond0

systemctl restart network

EOF

cat > /root/nic.restore.sh << 'EOF'
#!/bin/bash

set -x 

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete  ${i} ; done 

# re-create primary connection 
nmcli con add type ethernet \
    con-name eno1 \
    ifname eno1 \
    ipv4.method 'manual' \
    ipv4.address '39.134.201.65/27' \
    ipv4.gateway '39.134.201.94' \
    ipv4.dns '117.177.241.16'

systemctl restart network

exit 0
EOF

chmod +x /root/nic.restore.sh

cat > ~/cron-network-con-recreate << EOF
*/20 * * * * /bin/bash /root/nic.restore.sh
EOF

crontab ~/cron-network-con-recreate

bash /root/nic.bond.sh

# debug
cat /proc/net/bonding/bond0
cat /sys/class/net/bond*/bonding/xmit_hash_policy
# https://access.redhat.com/solutions/666853
ip -s -h link show master bond0
```

### worker-2 host

```bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum --disableplugin=subscription-manager  repolist

yum install -y byobu htop iostat

yum -y update

hostnamectl set-hostname worker-2.ocpsc.redhat.ren

nmcli connection modify eno1 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up eno1

yum -y install fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

EOF

systemctl enable fail2ban
systemctl restart fail2ban

cat << EOF > /etc/fail2ban/jail.d/wzh.conf
[sshd]
enabled = true

[recidive]
enabled = true

EOF

systemctl restart fail2ban

fail2ban-client status sshd
fail2ban-client status recidive
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

lsblk | grep 5.5 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk
lsblk | grep 5.5 | awk '{print $1}' | wc -l
# 24

yum install -y lvm2

pvcreate -y /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

vgcreate datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

vgs

lvcreate --type raid0 -l 100%FREE --stripes 24 -n datalv datavg

mkfs.xfs /dev/datavg/datalv

lvdisplay /dev/datavg/datalv -m

mkdir -p /data

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                  xfs     defaults        0 0

EOF

mount -a

yum install -y sysstat
lsblk | grep disk | awk '{print $1}' | xargs -I DEMO echo -n "DEMO "
# sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl sdm
iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk 5
iostat -m -x dm-10 5


########################################
# ntp
yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

systemctl disable --now firewalld.service

# setup time server
/bin/cp -f /etc/chrony.conf /etc/chrony.conf.bak

cat << EOF > /etc/chrony.conf
server 117.177.241.16 iburst
server 0.rhel.pool.ntp.org iburst
server 1.rhel.pool.ntp.org iburst
server 2.rhel.pool.ntp.org iburst
server 3.rhel.pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking
chronyc sources -v

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking


```

### worker-2 disk
```bash


#########################################
# ssd cache + hdd
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/logical_volume_manager_administration/index#lvm_cache_volume_creation
umount /data
lsblk -d -o name,rota

lvremove  /dev/datavg/datalv

# lsblk | grep 894 | awk '{print $1}'

pvcreate /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/vg_grow
vgextend datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

## raid5

lvcreate --type raid5 -L 1G --stripes 23 -n hddlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 1G --stripes 23 -n mixlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 1G --stripes 9 -n ssdlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai


lvcreate --type raid5 -L 3T --stripes 23 -n mix0lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx


lvcreate --type raid0 -L 1.3536T --stripes 10 -n cachemix0 datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 13G --stripes 10 -n cachemix0meta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cachemix0meta datavg/cachemix0

lvconvert --type cache --cachepool datavg/cachemix0 datavg/mix0lv

# lvcreate --type raid5 --stripes 9 -L 1T -I 16M -R 4096K -n hddlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk


## raid0 + stripe



lvcreate --type raid0 -L 1T --stripes 24 -n hdd0lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/hdd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=2453MiB/s (2572MB/s), 2453MiB/s-2453MiB/s (2572MB/s-2572MB/s), io=98.0GiB (106GB), run=41331-41331msec
#   WRITE: bw=24.9MiB/s (26.1MB/s), 24.9MiB/s-24.9MiB/s (26.1MB/s-26.1MB/s), io=1029MiB (1079MB), run=41331-41331msec
lvs -o+stripesize,chunksize datavg/hdd0lv
  # LV     VG     Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe Chunk
  # hdd0lv datavg rwi-aor--- 1.00t                                                     64.00k    0
lvremove -f datavg/hdd0lv

lvcreate --type raid0 -L 1T -I 128 --stripes 24 -n hdd1lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/hdd1lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=2674MiB/s (2804MB/s), 2674MiB/s-2674MiB/s (2804MB/s-2804MB/s), io=98.0GiB (106GB), run=37912-37912msec
#   WRITE: bw=27.1MiB/s (28.4MB/s), 27.1MiB/s-27.1MiB/s (28.4MB/s-28.4MB/s), io=1029MiB (1079MB), run=37912-37912msec
lvs -o+stripesize,chunksize datavg/hdd1lv
  # LV     VG     Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe  Chunk
  # hdd1lv datavg rwi-a-r--- 1.00t                                                     128.00k    0
lvremove -f datavg/hdd1lv

lvcreate --type raid0 -L 1T -I 256 --stripes 24 -n hdd1lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/hdd1lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=2674MiB/s (2804MB/s), 2674MiB/s-2674MiB/s (2804MB/s-2804MB/s), io=98.0GiB (106GB), run=37912-37912msec
#   WRITE: bw=27.1MiB/s (28.4MB/s), 27.1MiB/s-27.1MiB/s (28.4MB/s-28.4MB/s), io=1029MiB (1079MB), run=37912-37912msec
lvs -o+stripesize,chunksize datavg/hdd1lv
  # LV     VG     Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe  Chunk
  # hdd1lv datavg rwi-a-r--- 1.00t                                                     256.00k    0k    0
lvremove -f datavg/hdd1lv


lvcreate --type raid0 -L 300G --stripes 10 -n ssd0lv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=2602MiB/s (2728MB/s), 2602MiB/s-2602MiB/s (2728MB/s-2728MB/s), io=98.0GiB (106GB), run=38965-38965msec
#   WRITE: bw=26.4MiB/s (27.7MB/s), 26.4MiB/s-26.4MiB/s (27.7MB/s-27.7MB/s), io=1029MiB (1079MB), run=38965-38965msec
lvs -o+stripesize,chunksize datavg/ssd0lv
  # LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe Chunk
  # ssd0lv datavg rwi-a-r--- 300.00g                                                     64.00k    0
lvremove -f datavg/ssd0lv

lvcreate --type raid0 -L 300G -I 128 --stripes 10 -n ssd0lv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=2438MiB/s (2556MB/s), 2438MiB/s-2438MiB/s (2556MB/s-2556MB/s), io=98.0GiB (106GB), run=41584-41584msec
#   WRITE: bw=24.7MiB/s (25.9MB/s), 24.7MiB/s-24.7MiB/s (25.9MB/s-25.9MB/s), io=1029MiB (1079MB), run=41584-41584msec
lvs -o+stripesize,chunksize datavg/ssd0lv
  # LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe  Chunk
  # ssd0lv datavg rwi-a-r--- 300.00g                                                     128.00k    0
lvremove -f datavg/ssd0lv

lvcreate --type raid0 -L 300G -I 256 --stripes 10 -n ssd0lv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=1908MiB/s (2000MB/s), 1908MiB/s-1908MiB/s (2000MB/s-2000MB/s), io=98.0GiB (106GB), run=53135-53135msec
#   WRITE: bw=19.4MiB/s (20.3MB/s), 19.4MiB/s-19.4MiB/s (20.3MB/s-20.3MB/s), io=1029MiB (1079MB), run=53135-53135msec
lvs -o+stripesize,chunksize datavg/ssd0lv
  LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe  Chunk
  # ssd0lv datavg rwi-a-r--- 300.00g                                                     256.00k    0   0
lvremove -f datavg/ssd0lv


lvcreate --type raid5 -L 120G --stripes 23 -n hdd5lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/hdd5lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=474MiB/s (497MB/s), 474MiB/s-474MiB/s (497MB/s-497MB/s), io=98.0GiB (106GB), run=214073-214073msec
#   WRITE: bw=4920KiB/s (5038kB/s), 4920KiB/s-4920KiB/s (5038kB/s-5038kB/s), io=1029MiB (1079MB), run=214073-214073msec
lvs -o+stripesize,chunksize datavg/hdd5lv
  # LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe Chunk
  # hdd5lv datavg rwi-a-r--- 120.03g                                    100.00           64.00k    0
lvremove -f datavg/hdd5lv


lvcreate --type raid5 -L 120G -I 128 --stripes 23 -n hdd5lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/hdd5lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=449MiB/s (471MB/s), 449MiB/s-449MiB/s (471MB/s-471MB/s), io=98.0GiB (106GB), run=225892-225892msec
#   WRITE: bw=4663KiB/s (4775kB/s), 4663KiB/s-4663KiB/s (4775kB/s-4775kB/s), io=1029MiB (1079MB), run=225892-225892msec
lvs -o+stripesize,chunksize datavg/hdd5lv
  # LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe  Chunk
  # hdd5lv datavg rwi-a-r--- 120.03g                                    100.00           128.00k    0
lvremove -f datavg/hdd5lv


lvcreate --type raid5 -L 120G --stripes 23 -n mixtestlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 40G --stripes 10 -n cachetest datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 1G --stripes 10 -n cache1testmeta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cache1testmeta datavg/cachetest

lvconvert --type cache --cachepool datavg/cachetest datavg/mixtestlv

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/mixtestlv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=449MiB/s (471MB/s), 449MiB/s-449MiB/s (471MB/s-471MB/s), io=98.0GiB (106GB), run=225892-225892msec
#   WRITE: bw=4663KiB/s (4775kB/s), 4663KiB/s-4663KiB/s (4775kB/s-4775kB/s), io=1029MiB (1079MB), run=225892-225892msec
lvs -o+stripesize,chunksize datavg/mixtestlv
  # LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe  Chunk
  # hdd5lv datavg rwi-a-r--- 120.03g                                    100.00           128.00k    0
lvremove -f datavg/mixtestlv



lvcreate --type raid0 -L 1T --stripes 24 -n hdd1lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

fio --rw=randrw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/hdd1lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=2453MiB/s (2572MB/s), 2453MiB/s-2453MiB/s (2572MB/s-2572MB/s), io=98.0GiB (106GB), run=41331-41331msec
#   WRITE: bw=24.9MiB/s (26.1MB/s), 24.9MiB/s-24.9MiB/s (26.1MB/s-26.1MB/s), io=1029MiB (1079MB), run=41331-41331msec
lvs -o+stripesize,chunksize datavg/hdd1lv
  # LV     VG     Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe Chunk
  # hdd0lv datavg rwi-aor--- 1.00t                                                     64.00k    0
lvremove -f datavg/hdd1lv



lvcreate --type raid0 -L 300G --stripes 10 -n ssd0lv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

fio --rw=randrw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --filename=/dev/datavg/ssd0lv --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=1 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 
# Run status group 0 (all jobs):
#    READ: bw=1527MiB/s (1601MB/s), 1527MiB/s-1527MiB/s (1601MB/s-1601MB/s), io=98.0GiB (106GB), run=66375-66375msec
#   WRITE: bw=15.5MiB/s (16.2MB/s), 15.5MiB/s-15.5MiB/s (16.2MB/s-16.2MB/s), io=1029MiB (1079MB), run=66375-66375msec
lvs -o+stripesize,chunksize datavg/ssd0lv
  # LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert Stripe Chunk
  # ssd0lv datavg rwi-a-r--- 300.00g                                                     64.00k    0
lvremove -f datavg/ssd0lv








lvcreate --type raid0 -L 1G --stripes 24 -n hddlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx



lvcreate --type raid0 -L 130T --stripes 24 -n mixlv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

# lvcreate --type raid0 -L 300G --stripes 10 -n ssdlv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 8.6T --stripes 10 -n cache1 datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 40G --stripes 10 -n cache1meta datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool --poolmetadata datavg/cache1meta datavg/cache1

# lvs -a -o name,size,attr,devices datavg

lvconvert --type cache --cachepool datavg/cache1 datavg/mixlv

lvconvert --splitcache datavg/mixlv

# lvs -a -o name,size,attr,devices datavg
# lvs -o+cache_mode datavg

mkfs.xfs /dev/datavg/hddlv
mkfs.xfs /dev/datavg/ssdlv
mkfs.xfs /dev/datavg/mixlv
mkfs.xfs /dev/datavg/mix0lv

mkdir -p /data/
mkdir -p /data_ssd/
mkdir -p /data_mix/
mkdir -p /data_mix0

cat /etc/fstab

cat << EOF >> /etc/fstab
/dev/datavg/hddlv /data                  xfs     defaults        0 0
/dev/datavg/ssdlv /data_ssd                  xfs     defaults        0 0
/dev/datavg/mixlv /data_mix                  xfs     defaults        0 0
/dev/datavg/mix0lv  /data_mix0                  xfs     defaults        0 0
EOF

mount -a
df -h | grep \/data

dd if=/dev/zero of=/data/testfile bs=4k count=9999 oflag=dsync
dd if=/dev/zero of=/data_ssd/testfile bs=4k count=9999 oflag=dsync
dd if=/dev/zero of=/data_mix/testfile bs=4k count=9999 oflag=dsync

dd if=/dev/zero of=/data/testfile bs=4M count=9999 oflag=dsync
dd if=/dev/zero of=/data_ssd/testfile bs=4M count=9999 oflag=dsync
dd if=/dev/zero of=/data_mix/testfile bs=4M count=9999 oflag=dsync

dd if=/dev/zero of=/data/testfile.large bs=4M count=9999 oflag=direct
dd if=/dev/zero of=/data_ssd/testfile.large bs=4M count=9999 oflag=direct
dd if=/dev/zero of=/data_mix/testfile.large bs=4M count=9999 oflag=direct

dd if=/dev/zero of=/data/testfile.large bs=4M count=9999
dd if=/dev/zero of=/data_ssd/testfile.large bs=4M count=9999 
dd if=/dev/zero of=/data_mix/testfile.large bs=4M count=9999 

dd if=/data/testfile.large of=/dev/null bs=4k count=9999 oflag=dsync
dd if=/data_ssd/testfile.large of=/dev/null bs=4k count=9999 oflag=dsync
dd if=/data_mix/testfile.large of=/dev/null bs=4k count=999999 oflag=dsync

dd if=/data/testfile.large of=/dev/null bs=4M count=9999 oflag=dsync
dd if=/data_ssd/testfile.large of=/dev/null bs=4M count=9999 oflag=dsync
dd if=/data_mix/testfile.large of=/dev/null bs=4M count=9999 oflag=dsync

dd if=/data/testfile.large of=/dev/null bs=4M count=9999
dd if=/data_ssd/testfile.large of=/dev/null bs=4M count=9999
dd if=/data_mix/testfile.large of=/dev/null bs=4M count=9999

# cleanup
umount /data/
umount /data_ssd/
umount /data_mix/
umount /data_mix0/
lvremove -f /dev/datavg/hddlv
lvremove -f /dev/datavg/ssdlv
lvremove -f /dev/datavg/mixlv
lvremove -f /dev/datavg/mix0lv


# ssd tunning
# https://serverfault.com/questions/80134/linux-md-vs-lvm-performance
hdparm -tT /dev/md0

# https://www.ibm.com/developerworks/cn/linux/l-lo-io-scheduler-optimize-performance/index.html
cat /sys/block/*/queue/scheduler

lsblk | grep 894 | awk '{print $1}' | xargs -I DEMO cat /sys/block/DEMO/queue/scheduler

lsblk | grep 894 | awk '{print "echo deadline > /sys/block/"$1"/queue/scheduler"}' 

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --directory=./ --ioengine=libaio --numjobs=1 --thread \
    --norandommap --runtime=300 --direct=0 --iodepth=8 \
    --scramble_buffers=1 --offset=0 --size=100g 

fio --rw=rw --rwmixread=99 --bsrange=4k-256k --name=vdo \
    --directory=./ --ioengine=sync --size=100g 

blktrace /dev/datavg/mix0lv /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai     /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

blkparse -o /dev/null -i dm-244 -d dm-244.bin
btt -i dm-244.bin | less

blkparse -o /dev/null -i sdaa -d sdaa.bin
btt -i sdaa.bin | less

blkparse -o /dev/null -i sda -d sda.bin
btt -i sda.bin | less


blktrace /dev/datavg/ssd0lv /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai    


lvmconfig --typeconfig default --withcomments --withspaces

lvmconfig --type default --withcomments allocation/cache_policy
lvmconfig --type default --withcomments allocation/cache_settings
lvmconfig --type list --withcomments allocation/cache_settings

iostat -x -m 3 /dev/mapper/datavg-mixlv sdh sdab

dstat -D /dev/mapper/datavg-mixlv,/dev/mapper/datavg-mixlv_corig,sdh,sdab -N bond0

dstat -D /dev/mapper/datavg-mixlv,/dev/mapper/datavg-mixlv_corig,sdh,sdab --disk-util 

bmon -p eno1,eno2,ens2f0,ens2f1,bond0

lvs -o+lv_all datavg/mixlv_corig

lvs -o+Layout datavg/mixlv_corig

lvs -o+CacheReadHits,CacheReadMisses

lvs -o+Layout


blockdev --report    
# RO    RA   SSZ   BSZ   StartSec            Size   Device
# rw  8192   512  4096          0    478998953984   /dev/sdy
# rw  8192   512   512       2048      1073741824   /dev/sdy1
# rw  8192   512  4096    2099200      1073741824   /dev/sdy2
# rw  8192   512  4096    4196352    476849373184   /dev/sdy3
# rw  8192   512  4096          0    958999298048   /dev/sdaj
# rw  8192   512  4096       2048    958998249472   /dev/sdaj1
# rw  8192   512  4096          0   6001175126016   /dev/sda
# rw  8192   512  4096          0   6001175126016   /dev/sdd
# rw  8192   512  4096          0   6001175126016   /dev/sde
# rw  8192   512  4096          0   6001175126016   /dev/sdc
# rw  8192   512  4096          0   6001175126016   /dev/sdf
# rw  8192   512  4096          0   6001175126016   /dev/sdb
# rw  8192   512  4096          0   6001175126016   /dev/sdg
# rw  8192   512  4096          0   6001175126016   /dev/sdh
# rw  8192   512  4096          0   6001175126016   /dev/sdk
# rw  8192   512  4096          0   6001175126016   /dev/sdi
# rw  8192   512  4096          0   6001175126016   /dev/sdm
# rw  8192   512  4096          0   6001175126016   /dev/sdj
# rw  8192   512  4096          0   6001175126016   /dev/sdl
# rw  8192   512  4096          0   6001175126016   /dev/sdn
# rw  8192   512  4096          0   6001175126016   /dev/sdo
# rw  8192   512  4096          0   6001175126016   /dev/sdp
# rw  8192   512  4096          0   6001175126016   /dev/sdx
# rw  8192   512  4096          0   6001175126016   /dev/sdq
# rw  8192   512  4096          0   6001175126016   /dev/sdr
# rw  8192   512  4096          0   6001175126016   /dev/sdu
# rw  8192   512  4096          0   6001175126016   /dev/sdw
# rw  8192   512  4096          0   6001175126016   /dev/sds
# rw  8192   512  4096          0   6001175126016   /dev/sdt
# rw  8192   512  4096          0   6001175126016   /dev/sdv
# rw  8192   512  4096          0    960197124096   /dev/sdz
# rw  8192   512  4096          0    960197124096   /dev/sdaa
# rw  8192   512  4096          0    960197124096   /dev/sdac
# rw  8192   512  4096          0    960197124096   /dev/sdab
# rw  8192   512  4096          0    960197124096   /dev/sdad
# rw  8192   512  4096          0    960197124096   /dev/sdae
# rw  8192   512  4096          0    960197124096   /dev/sdag
# rw  8192   512  4096          0    960197124096   /dev/sdaf
# rw  8192   512  4096          0    960197124096   /dev/sdai
# rw  8192   512  4096          0    960197124096   /dev/sdah
# rw  8192   512  4096          0   5955689381888   /dev/dm-0
# rw  8192   512  4096          0   5955689381888   /dev/dm-1
# rw  8192   512  4096          0   5955689381888   /dev/dm-2
# rw  8192   512  4096          0   5955689381888   /dev/dm-3
# rw  8192   512  4096          0   5955689381888   /dev/dm-4
# rw  8192   512  4096          0   5955689381888   /dev/dm-5
# rw  8192   512  4096          0   5955689381888   /dev/dm-6
# rw  8192   512  4096          0   5955689381888   /dev/dm-7
# rw  8192   512  4096          0   5955689381888   /dev/dm-8
# rw  8192   512  4096          0   5955689381888   /dev/dm-9
# rw  8192   512  4096          0   5955689381888   /dev/dm-10
# rw  8192   512  4096          0   5955689381888   /dev/dm-11
# rw  8192   512  4096          0   5955689381888   /dev/dm-12
# rw  8192   512  4096          0   5955689381888   /dev/dm-13
# rw  8192   512  4096          0   5955689381888   /dev/dm-14
# rw  8192   512  4096          0   5955689381888   /dev/dm-15
# rw  8192   512  4096          0   5955689381888   /dev/dm-16
# rw  8192   512  4096          0   5955689381888   /dev/dm-17
# rw  8192   512  4096          0   5955689381888   /dev/dm-18
# rw  8192   512  4096          0   5955689381888   /dev/dm-19
# rw  8192   512  4096          0   5955689381888   /dev/dm-20
# rw  8192   512  4096          0   5955689381888   /dev/dm-21
# rw  8192   512  4096          0   5955689381888   /dev/dm-22
# rw  8192   512  4096          0   5955689381888   /dev/dm-23
# rw  8192   512  4096          0 142936545165312   /dev/dm-24
# rw  8192   512  4096          0    945580670976   /dev/dm-25
# rw  8192   512  4096          0    945580670976   /dev/dm-26
# rw  8192   512  4096          0    945580670976   /dev/dm-27
# rw  8192   512  4096          0    945580670976   /dev/dm-28
# rw  8192   512  4096          0    945580670976   /dev/dm-29
# rw  8192   512  4096          0    945580670976   /dev/dm-30
# rw  8192   512  4096          0    945580670976   /dev/dm-31
# rw  8192   512  4096          0    945580670976   /dev/dm-32
# rw  8192   512  4096          0    945580670976   /dev/dm-33
# rw  8192   512  4096          0    945580670976   /dev/dm-34
# rw  8192   512  4096          0   9455806709760   /dev/dm-35
# rw  8192   512  4096          0      4294967296   /dev/dm-36
# rw  8192   512  4096          0      4294967296   /dev/dm-37
# rw  8192   512  4096          0      4294967296   /dev/dm-38
# rw  8192   512  4096          0      4294967296   /dev/dm-39
# rw  8192   512  4096          0      4294967296   /dev/dm-40
# rw  8192   512  4096          0      4294967296   /dev/dm-41
# rw  8192   512  4096          0      4294967296   /dev/dm-42
# rw  8192   512  4096          0      4294967296   /dev/dm-43
# rw  8192   512  4096          0      4294967296   /dev/dm-44
# rw  8192   512  4096          0      4294967296   /dev/dm-45
# rw  8192   512  4096          0     42949672960   /dev/dm-46
# rw  8192   512  4096          0 142936545165312   /dev/dm-47
# rw  8192   512  4096          0        46137344   /dev/dm-48
# rw  8192   512  4096          0        46137344   /dev/dm-49
# rw  8192   512  4096          0        46137344   /dev/dm-50
# rw  8192   512  4096          0        46137344   /dev/dm-51
# rw  8192   512  4096          0        46137344   /dev/dm-52
# rw  8192   512  4096          0        46137344   /dev/dm-53
# rw  8192   512  4096          0        46137344   /dev/dm-54
# rw  8192   512  4096          0        46137344   /dev/dm-55
# rw  8192   512  4096          0        46137344   /dev/dm-56
# rw  8192   512  4096          0        46137344   /dev/dm-57
# rw  8192   512  4096          0        46137344   /dev/dm-58
# rw  8192   512  4096          0        46137344   /dev/dm-59
# rw  8192   512  4096          0        46137344   /dev/dm-60
# rw  8192   512  4096          0        46137344   /dev/dm-61
# rw  8192   512  4096          0        46137344   /dev/dm-62
# rw  8192   512  4096          0        46137344   /dev/dm-63
# rw  8192   512  4096          0        46137344   /dev/dm-64
# rw  8192   512  4096          0        46137344   /dev/dm-65
# rw  8192   512  4096          0        46137344   /dev/dm-66
# rw  8192   512  4096          0        46137344   /dev/dm-67
# rw  8192   512  4096          0        46137344   /dev/dm-68
# rw  8192   512  4096          0        46137344   /dev/dm-69
# rw  8192   512  4096          0        46137344   /dev/dm-70
# rw  8192   512  4096          0        46137344   /dev/dm-71
# rw  8192   512  4096          0      1107296256   /dev/dm-72    

# https://access.redhat.com/solutions/3588841
/sbin/blockdev --setra 4096 /dev/mapper/datavg-mixlv
/sbin/blockdev --setra 8192 /dev/mapper/datavg-mixlv
/sbin/blockdev --setra 16384 /dev/mapper/datavg-mixlv
/sbin/blockdev --setra 32768 /dev/mapper/datavg-mixlv
/sbin/blockdev --setra 65536 /dev/mapper/datavg-mixlv
/sbin/blockdev --setra 131072 /dev/mapper/datavg-mixlv
/sbin/blockdev --setra 262144 /dev/mapper/datavg-mixlv

# final config
/sbin/blockdev --setra 16384 /dev/mapper/datavg-mixlv
for f in /dev/mapper/datavg-mixlv_corig_rimage_*; do /sbin/blockdev --setra 16384  $f ; done

# worker2
# 5.5
find /data_mix/mnt/ -type f > list
dstat --output /root/dstat.csv -D /dev/mapper/datavg-mixlv,/dev/mapper/datavg-mixlv_corig,sdh,sdab -N bond0

var_basedir="/data_mix/mnt"
find $var_basedir -type f -size -511M  > list.512m
find $var_basedir -type f -size -2049M  -size +511M > list.2g
find $var_basedir -type f -size +2049M > list.+2g

cat list | shuf > list.shuf.all

cat list.512m | shuf > list.shuf.512m
cat list.2g | shuf > list.shuf.2g
cat list.+2g | shuf > list.shuf.+2g
cat list.2g list.+2g | shuf > list.shuf.+512m

rm -f split.list.*
# zte use 1800
var_total=10
# split -n l/$var_total list.shuf.all split.list.all.
split -n l/$var_total list.shuf.512m split.list.512m.
split -n l/$var_total list.shuf.2g split.list.2g.
split -n l/$var_total list.shuf.+2g split.list.+2g.
split -n l/$var_total list.shuf.+512m split.list.+512m.

for f in split.list.512m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
# for f in split.list.+512m.*; do 
#     cat $f | xargs -I DEMO cat DEMO > /dev/null &
# done
for f in split.list.2g.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
for f in split.list.+2g.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

ps -ef | grep /data_mix/mnt | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO

tmux kill-window -t 3


# rm -f split.*

# 2.8
var_num=`echo "scale=0;$(cat list | wc -l  )/5" | bc -l`
head -n $var_num list > list.20
tail -n +$var_num list > list.80

var_total=1500
# split -n l/$(echo "scale=0;$var_total/5*4"|bc -l) list.20 split.list.20.
# while true; do
#   for f in split.list.20.*; do 
#       cat $f | xargs -I DEMO cat DEMO > /dev/null &
#   done
#   echo "wait to finish"
#   wait
# done
var_runtimes=$(echo "scale=0;$var_total/5*4"|bc -l)
while true; do
  for ((i=1; i<=$var_runtimes; i++)); do
    echo "Welcome $i times"
    cat list.20 | shuf | xargs -I DEMO cat DEMO > /dev/null &
  done
  echo "wait to finish"
  wait
done

var_total=1500
# split -n l/$(echo "scale=0;$var_total/5*1"|bc -l) list.80 split.list.80.
# while true; do
#   for f in split.list.80.*; do 
#       cat $f | xargs -I DEMO cat DEMO > /dev/null &
#   done
#   echo "wait to finish"
#   wait
# done
var_runtimes=$(echo "scale=0;$var_total/5*1"|bc -l)
while true; do
  for ((i=1; i<=$var_runtimes; i++)); do
    echo "Welcome $i times"
    cat list.80 | shuf | xargs -I DEMO cat DEMO > /dev/null &
  done
  echo "wait to finish"
  wait
done
# 500M-1.2GB/s
ps -ef | grep /data_mix/mnt | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO



```

### worker-2 disk tunning

```bash 

# 8.6T cache / 130T hdd = 6.6%
# 660G cache / 10T hdd 

lvcreate --type raid0 -L 10T --stripesize 2048k --stripes 24 -n ext02lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 10T --stripesize 4096k --stripes 24 -n ext04lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 10T --stripesize 2048k --stripes 23 -n ext52lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 10T --stripesize 2048k --stripes 11 -n ext52lv12 datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl 



lvcreate --type raid0 -L 10T --stripesize 2048k --stripes 24 -n xfs02lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid0 -L 10T --stripesize 4096k --stripes 24 -n xfs04lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 10T --stripesize 2048k --stripes 23 -n xfs52lv datavg /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx

lvcreate --type raid5 -L 10T --stripesize 2048k --stripes 11 -n xfs52lv12 datavg /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx


lvcreate --type raid0 -L 3.5T --stripesize 1024k --stripes 10 -n ext01lvssd datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 3.5T --stripesize 1024k --stripes 10 -n xfs01lvssd datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvcreate --type raid0 -L 700G --stripesize 2048k --stripes 10 -n cachelv datavg /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag /dev/sdah /dev/sdai

lvconvert --type cache-pool datavg/cachelv

lvconvert --type cache --cachepool datavg/cachelv datavg/ext02lv

# lvconvert --splitcache datavg/ext02lv
# lvconvert --uncache datavg/ext02lv

lvs -o+layout,stripesize
  # LV         VG     Attr       LSize  Pool      Origin          Data%  Meta%  Move Log Cpy%Sync Convert Layout              Stripe
  # ext01lvssd datavg rwi-a-r---  3.50t                                                                   raid,raid0           1.00m
  # ext02lv    datavg Cwi-a-C--- 10.00t [cachelv] [ext02lv_corig] 0.01   16.41           0.00             cache                   0
  # ext04lv    datavg rwi-a-r--- 10.00t                                                                   raid,raid0           4.00m
  # ext52lv    datavg rwi-a-r--- 10.00t                                                  9.72             raid,raid5,raid5_ls  2.00m
  # xfs01lvssd datavg rwi-a-r---  3.50t                                                                   raid,raid0           1.00m

mkdir -p /data_ext02
mkdir -p /data_ext04
mkdir -p /data_ext52
mkdir -p /data_ext01
mkdir -p /data_xfs01
mkdir -p /data_xfs02
mkdir -p /data_xfs04
mkdir -p /data_xfs52

mkdir -p /data_ext52_12
mkdir -p /data_xfs52_12

mkfs.ext4 /dev/datavg/ext02lv
mkfs.ext4 /dev/datavg/ext04lv
mkfs.ext4 /dev/datavg/ext52lv
mkfs.ext4 /dev/datavg/ext01lvssd
mkfs.xfs  /dev/datavg/xfs01lvssd
mkfs.xfs  /dev/datavg/xfs02lv
mkfs.xfs  /dev/datavg/xfs04lv
mkfs.xfs  /dev/datavg/xfs52lv

mkfs.ext4 /dev/datavg/ext52lv12
mkfs.xfs  /dev/datavg/xfs52lv12

mount /dev/datavg/ext02lv /data_ext02
mount /dev/datavg/ext04lv /data_ext04
mount /dev/datavg/ext52lv /data_ext52
mount /dev/datavg/ext01lvssd /data_ext01
mount /dev/datavg/xfs01lvssd /data_xfs01
mount /dev/datavg/xfs02lv /data_xfs02
mount /dev/datavg/xfs04lv /data_xfs04
mount /dev/datavg/xfs52lv /data_xfs52

mount /dev/datavg/ext52lv12 /data_ext52_12
mount /dev/datavg/xfs52lv12 /data_xfs52_12

dstat -d -D /dev/datavg/ext02lv,/dev/datavg/ext04lv,/dev/datavg/ext52lv,/dev/datavg/ext01lvssd,/dev/datavg/xfs01lvssd,/dev/datavg/xfs02lv,/dev/datavg/xfs04lv,/dev/datavg/xfs52lv,/dev/datavg/ext52lv12,/dev/datavg/xfs52lv12,/dev/sdaa
dstat -d -D /dev/datavg/ext02lv,/dev/datavg/ext04lv,/dev/datavg/ext52lv,/dev/datavg/ext01lvssd,/dev/datavg/xfs01lvssd,/dev/datavg/xfs02lv,/dev/datavg/xfs04lv,/dev/datavg/xfs52lv,/dev/datavg/ext52lv12,/dev/datavg/xfs52lv12,/dev/sdaa,/dev/sdb --disk-util
bmon -p bond0,enp*

# on worker1
rclone config
rclone lsd worker-2:
rclone sync /data_ssd/mnt/ worker-2:/data_ext01/mnt/ -P -L --transfers 64


# on worker-2

# fill data
# for 256M
var_basedir_ext="/data_ext04/mnt"

mkdir -p $var_basedir_ext

# how may write concurrency
var_total_write=10
# how much size each file, this value is in MB
# 512M
var_size=512
# how much size to write totally, in TB
# write 3T
var_total_size=3

var_number=$(echo "scale=0;$var_total_size*1024*1024/$var_size/$var_total_write"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total_write; j++)); do
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done



# fill data
# for 1G
var_basedir_ext="/data_ext04/mnt"

mkdir -p $var_basedir_ext

# how may write concurrency
var_total_write=10
# how much size each file, this value is in MB
# 512M
var_size=1024
# how much size to write totally, in TB
# write 3T
var_total_size=3

var_number=$(echo "scale=0;$var_total_size*1024*1024/$var_size/$var_total_write"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total_write; j++)); do
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done



# fill data
# for 2G
var_basedir_ext="/data_ext04/mnt"

mkdir -p $var_basedir_ext

# how may write concurrency
var_total_write=10
# how much size each file, this value is in MB
# 512M
var_size=2048
# how much size to write totally, in TB
# write 3T
var_total_size=3

var_number=$(echo "scale=0;$var_total_size*1024*1024/$var_size/$var_total_write"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total_write; j++)); do
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done


# copy data
rclone sync /data_ext01/mnt/ /data_xfs01/mnt/ -P -L --transfers 64
rclone sync /data_ext04/mnt/ /data_xfs02/mnt/ -P -L --transfers 64

rclone sync /data_ext04/mnt/ /data_xfs04/mnt/ -P -L --transfers 10
rclone sync /data_ext04/mnt/ /data_xfs52/mnt/ -P -L --transfers 10
rclone sync /data_ext04/mnt/ /data_xfs52_12/mnt/ -P -L --transfers 10

rclone sync /data_ext04/mnt/ /data_ext02/mnt/ -P -L --transfers 10
rclone sync /data_ext04/mnt/ /data_ext52/mnt/ -P -L --transfers 10
rclone sync /data_ext04/mnt/ /data_ext52_12/mnt/ -P -L --transfers 10





```

### worker-2 nic bond
```bash
ip link show
# 2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bb:80 brd ff:ff:ff:ff:ff:ff
# 3: ens2f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether 08:4f:0a:b5:a4:6e brd ff:ff:ff:ff:ff:ff
# 4: eno2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bb:81 brd ff:ff:ff:ff:ff:ff
# 5: eno3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bb:82 brd ff:ff:ff:ff:ff:ff
# 6: ens2f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether 08:4f:0a:b5:a4:6f brd ff:ff:ff:ff:ff:ff
# 7: eno4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
#     link/ether cc:64:a6:59:bb:83 brd ff:ff:ff:ff:ff:ff

ip a s eno1
# 2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
#     link/ether cc:64:a6:59:bb:80 brd ff:ff:ff:ff:ff:ff
#     inet 39.134.201.66/27 brd 39.134.201.95 scope global noprefixroute eno1
#        valid_lft forever preferred_lft forever
#     inet6 fe80::f690:1c45:b8c3:96d/64 scope link noprefixroute
#        valid_lft forever preferred_lft forever

ethtool eno1  # 10000baseT/Full
ethtool eno2  # 10000baseT/Full
ethtool eno3  # 1000baseT/Full
ethtool eno4  # 1000baseT/Full
ethtool ens2f0  #  10000baseT/Full
ethtool ens2f1  #  10000baseT/Full

nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad 

nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3

nmcli con add type bond-slave ifname eno2 con-name eno2 master bond0
nmcli con add type bond-slave ifname ens2f0 con-name ens2f0 master bond0
nmcli con add type bond-slave ifname ens2f1 con-name ens2f1 master bond0

nmcli con down eno2
nmcli con up eno2
nmcli con down ens2f0
nmcli con up ens2f0
nmcli con down ens2f1
nmcli con up ens2f1
nmcli con down bond0
nmcli con start bond0     


#######################################
# nic bond
cat > /root/nic.bond.sh << 'EOF'
#!/bin/bash

set -x 

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete  ${i} ; done 

nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad \
    ipv4.method 'manual' \
    ipv4.address '39.134.201.66/27' \
    ipv4.gateway '39.134.201.94' \
    ipv4.dns '117.177.241.16'
    
nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3

nmcli con add type bond-slave ifname eno1 con-name eno1 master bond0    
nmcli con add type bond-slave ifname eno2 con-name eno2 master bond0
nmcli con add type bond-slave ifname ens2f0 con-name ens2f0 master bond0
nmcli con add type bond-slave ifname ens2f1 con-name ens2f1 master bond0

systemctl restart network

EOF

cat > /root/nic.restore.sh << 'EOF'
#!/bin/bash

set -x 

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete  ${i} ; done 

# re-create primary connection 
nmcli con add type ethernet \
    con-name eno1 \
    ifname eno1 \
    ipv4.method 'manual' \
    ipv4.address '39.134.201.66/27' \
    ipv4.gateway '39.134.201.94' \
    ipv4.dns '117.177.241.16'

systemctl restart network

exit 0
EOF

chmod +x /root/nic.restore.sh

cat > ~/cron-network-con-recreate << EOF
*/20 * * * * /bin/bash /root/nic.restore.sh
EOF

crontab ~/cron-network-con-recreate

bash /root/nic.bond.sh


```

### worker-3 host
```bash

systemctl stop firewalld
systemctl disable firewalld

cat << EOF > /etc/rc.local
#!/bin/bash
# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
# In contrast to previous versions due to parallel execution during boot
# this script will NOT be run after all other services.
#
# Please note that you must run 'chmod +x /etc/rc.d/rc.local' to ensure
# that this script will be executed during boot.

touch /var/lock/subsys/local

ipset create my-allow-set hash:net
ipset add my-allow-set 127.0.0.1/32
ipset add my-allow-set 223.87.20.0/24
ipset add my-allow-set 117.177.241.0/24
ipset add my-allow-set 39.134.200.0/24
ipset add my-allow-set 39.134.201.0/24
ipset add my-allow-set 39.137.101.0/24
ipset add my-allow-set 192.168.7.0/24
ipset add my-allow-set 112.44.102.224/27
ipset add my-allow-set 47.93.86.113/32
ipset add my-allow-set 221.226.0.75/32
ipset add my-allow-set 210.21.236.182/32
ipset add my-allow-set 61.132.54.2/32

ipset add my-allow-set 39.134.198.0/24

ipset add my-allow-set 39.134.204.0/24

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m set --match-set my-allow-set src -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# systemctl restart rc-local


#######################################
# nic bond
cat << 'EOF' > /root/nic.bond.sh
#!/bin/bash

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete uuid ${i} ; done 

nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad \
    ipv4.method 'manual' \
    ipv4.address '39.134.204.73/27' \
    ipv4.gateway '39.134.204.65' \
    ipv4.dns '117.177.241.16'
    
nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3
    
nmcli con add type bond-slave ifname enp176s0f0 con-name enp176s0f0 master bond0
nmcli con add type bond-slave ifname enp176s0f1 con-name enp176s0f1 master bond0

systemctl restart network

EOF

cat > /root/nic.restore.sh << 'EOF'
#!/bin/bash

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete uuid ${i} ; done 

# re-create primary connection 
nmcli con add type ethernet \
    con-name enp176s0f0 \
    ifname enp176s0f0 \
    ipv4.method 'manual' \
    ipv4.address '39.134.204.73/27' \
    ipv4.gateway '39.134.204.65' \
    ipv4.dns '117.177.241.16'

systemctl restart network

exit 0
EOF

chmod +x /root/nic.restore.sh

cat > ~/cron-network-con-recreate << EOF
*/2 * * * * /bin/bash /root/nic.restore.sh
EOF

crontab ~/cron-network-con-recreate



mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://117.177.241.16/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum --disableplugin=subscription-manager  repolist

yum -y update

hostnamectl set-hostname worker-3.ocpsc.redhat.ren

nmcli connection modify enp176s0f0 ipv4.dns 117.177.241.16
nmcli connection reload
nmcli connection up enp176s0f0



# ntp
yum install -y chrony
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
chronyc tracking

systemctl disable --now firewalld.service

# update ntp
cat << EOF > /etc/chrony.conf
server 223.87.20.100 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl status chronyd
chronyc tracking





```

### worker-3 disk

```bash
lshw -class disk

lsblk | grep 5.5 | awk '{print $1}' | xargs -I DEMO echo -n "/dev/DEMO "
# /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy
lsblk | grep 5.5 | awk '{print $1}' | wc -l
# 24

pvcreate -y /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy

vgcreate datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy

lsblk -d -o name,rota

lvcreate --type raid0 -L 120T  --stripesize 128k --stripes 24 -n hddlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy


mkfs.ext4 /dev/datavg/hddlv



lvcreate --type raid0 -L 5T  --stripesize 512k --stripes 24 -n xfslv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy

lvcreate --type raid0 -L 110T  --stripesize 4096k --stripes 24 -n extzxlv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy

lvcreate --type raid0 -L 3.5T  --stripesize 4096k --stripes 24 -n ext04lv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy

lvcreate --type raid6 -L 3.5T  --stripesize 2048k --stripes 22 -n ext62lv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy

lvcreate --type raid5 -L 3.5T  --stripesize 2048k --stripes 23 -n ext52lv datavg /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv /dev/sdw /dev/sdx /dev/sdy



mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/mapper/fc-root

mkfs.xfs /dev/datavg/xfslv
mkfs.ext4 /dev/datavg/extlv



mkfs.ext4 /dev/datavg/ext04lv
mkfs.ext4 /dev/datavg/ext62lv

mkfs.ext4 /dev/datavg/ext52lv

mkfs.ext4 /dev/datavg/extzxlv
# mkfs.xfs /dev/datavg/extzxlv
mount /dev/datavg/extzxlv /data
rclone sync /data_ext04/mnt/ /data/redhat_mnt/  -P -L --transfers 64

mount /dev/datavg/xfslv /data_xfs
mount /dev/datavg/extlv /data_ext

mkdir -p /data_ext02
mkdir -p /data_ext04
mkdir -p /data_ext62
mkdir -p /data_ext52

mount /dev/datavg/ext02lv /data_ext02
mount /dev/datavg/ext04lv /data_ext04
# mount /dev/datavg/ext62lv /data_ext62
mount /dev/datavg/ext52lv /data_ext52

umount /data_xfs
lvremove -f datavg/xfslv
# rsync --info=progress2 -P -ar  /data_ext/mnt/ /data_xfs/mnt/
rclone sync /data_ext/mnt/ /data_xfs/mnt/ -P -L --transfers 64

umount /data_ext
lvremove -f datavg/extlv
rclone sync /data_xfs/mnt/ /data_ext/mnt/ -P -L --transfers 64

umount /data_ext52
rclone sync /data_xfs/mnt/ /data_ext04/mnt/ -P -L --transfers 64
rclone sync /data_xfs/mnt/ /data_ext62/mnt/ -P -L --transfers 64
rclone sync /data_xfs/mnt/ /data_ext52/mnt/ -P -L --transfers 64

lvs -o+stripesize

dstat -D /dev/datavg/xfslv,/dev/datavg/extlv,/dev/sdb,/dev/sdc 5
dstat -D /dev/datavg/xfslv,/dev/datavg/extlv,/dev/sdb,/dev/sdc --disk-util
bmon -p bond0,enp*

blockdev --report 
# https://access.redhat.com/solutions/3588841
# orig: 12288
/sbin/blockdev --setra 131072 /dev/datavg/xfslv
/sbin/blockdev --setra 131072 /dev/datavg/extlv

/sbin/blockdev --setra 12288 /dev/datavg/xfslv
/sbin/blockdev --setra 12288 /dev/datavg/extlv


mkdir -p /data/

cat /etc/fstab

cat << EOF >> /etc/fstab
/dev/datavg/hddlv /data                  ext4     defaults        0 0
EOF

mount -a
df -h | grep \/data

while true; do df -h | grep /data; sleep 10; done

dstat -D /dev/datavg/hddlv 
dstat -D /dev/sdb,/dev/sdc
dstat -D /dev/sdb,/dev/sdc --disk-util

mkfs.xfs -f /dev/sdb
mkfs.ext4 -F /dev/sdc

mkdir -p /data_xfs
mkdir -p /data_ext

mount /dev/sdb /data_xfs
mount /dev/sdc /data_ext


# fill data
# for 1.5M
var_basedir_xfs="/data_xfs/mnt"
var_basedir_ext="/data_ext/mnt"

mkdir -p $var_basedir_xfs
mkdir -p $var_basedir_ext


var_basedir_xfs="/data_xfs/mnt"
var_basedir_ext="/data_ext/mnt"
var_total=10
# 512k
var_size=0.5
# write 1T
var_number=$(echo "scale=0;1024*1024/$var_size/$var_total"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total; j++)); do
    # echo "Welcome $i times"
    head -c ${var_len}K < /dev/urandom > $var_basedir_xfs/$var_size-$j-$i &
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done

var_basedir_xfs="/data_xfs/mnt"
var_basedir_ext="/data_ext/mnt"
var_total=10
# 4M
var_size=4
# write 1T
var_number=$(echo "scale=0;1024*1024/$var_size/$var_total"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total; j++)); do
    # echo "Welcome $i times"
    head -c ${var_len}K < /dev/urandom > $var_basedir_xfs/$var_size-$j-$i &
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done


var_basedir_xfs="/data_xfs/mnt"
var_basedir_ext="/data_ext/mnt"
var_total=10
# 8M
var_size=8
# write 1T
var_number=$(echo "scale=0;1024*1024/$var_size/$var_total"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total; j++)); do
    # echo "Welcome $i times"
    head -c ${var_len}K < /dev/urandom > $var_basedir_xfs/$var_size-$j-$i &
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done

var_basedir_xfs="/data_xfs/mnt"
var_basedir_ext="/data_ext/mnt"
var_total=10
# 32M
var_size=32
# write 1T
var_number=$(echo "scale=0;1024*1024/$var_size/$var_total"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total; j++)); do
    # echo "Welcome $i times"
    head -c ${var_len}K < /dev/urandom > $var_basedir_xfs/$var_size-$j-$i &
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done

var_basedir_xfs="/data_xfs/mnt"
var_basedir_ext="/data_ext/mnt"
var_total=10
# 64M
var_size=64
# write 1T
var_number=$(echo "scale=0;1024*1024/$var_size/$var_total"|bc -l)
var_len=$(echo "scale=0;$var_size*1024/1"|bc -l)

for ((i=1; i<=$var_number; i++)); do
  for ((j=1; j<=$var_total; j++)); do
    # echo "Welcome $i times"
    head -c ${var_len}K < /dev/urandom > $var_basedir_xfs/$var_size-$j-$i &
    head -c ${var_len}K < /dev/urandom > $var_basedir_ext/$var_size-$j-$i &
  done
  echo "wait to finish: $i"
  wait
done

mkdir -p /data_xfs/list.tmp
cd /data_xfs/list.tmp
var_basedir="/data_xfs/mnt"
find $var_basedir -type f -size -2M  > list.2m
find $var_basedir -type f -size -10M  -size +2M > list.10m
find $var_basedir -type f -size +10M > list.100m
find $var_basedir -type f > list


var_truebase="/data"
mkdir -p $var_truebase/list.tmp
cd $var_truebase/list.tmp

var_basedir="$var_truebase/redhat_mnt"
find $var_basedir -type f -size -2M  > list.2m
find $var_basedir -type f -size -10M  -size +2M > list.10m
find $var_basedir -type f -size +10M > list.100m
find $var_basedir -type f > list

cat list | xargs ls -l > list.size
cat list.size | awk '{ n=int(log($5)/log(2));                         \
          if (n<10) n=10;                                               \
          size[n]++ }                                                   \
      END { for (i in size) printf("%d %d\n", 2^i, size[i]) }'          \
 | sort -n                                                              \
 | awk 'function human(x) { x[1]/=1024;                                 \
                            if (x[1]>=1024) { x[2]++;                   \
                                              human(x) } }              \
        { a[1]=$1;                                                      \
          a[2]=0;                                                       \
          human(a);                                                     \
          printf("%3d - %4d %s: %6d\n", a[1], a[1]*2,substr("kMGTEPYZ",a[2]+1,1),$2) }' 





cat list | shuf > list.shuf.all

cat list.2m | shuf > list.shuf.2m
cat list.10m | shuf > list.shuf.10m
cat list.100m | shuf > list.shuf.100m
cat list.10m list.100m | shuf > list.shuf.+2m

rm -f split.list.*
# zte use 1800
var_total=10
split -n l/$var_total list.shuf.all split.list.all.
split -n l/$var_total list.shuf.2m split.list.2m.
split -n l/$var_total list.shuf.10m split.list.10m.
split -n l/$var_total list.shuf.100m split.list.100m.
split -n l/$var_total list.shuf.+2m split.list.+2m.

for f in split.list.2m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
# for f in split.list.+2m.*; do 
#     cat $f | xargs -I DEMO cat DEMO > /dev/null &
# done

for f in split.list.10m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done
for f in split.list.100m.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

for f in split.list.all.*; do 
    cat $f | xargs -I DEMO cat DEMO > /dev/null &
done

jobs -p | xargs kill

ps -ef | grep xargs | grep DEMO | grep cat | awk '{print $2}' | xargs -I DEMO kill DEMO



```

## install ocp

### helper node day1

```bash
############################################################
# on macbook
mkdir -p /Users/wzh/Documents/redhat/tools/redhat.ren/etc
mkdir -p /Users/wzh/Documents/redhat/tools/redhat.ren/lib
mkdir -p /Users/wzh/Documents/redhat/tools/ocpsc.redhat.ren/etc
mkdir -p /Users/wzh/Documents/redhat/tools/ocpsc.redhat.ren/lib
mkdir -p /Users/wzh/Documents/redhat/tools/apps.ocpsc.redhat.ren/etc
mkdir -p /Users/wzh/Documents/redhat/tools/apps.ocpsc.redhat.ren/lib

cd /Users/wzh/Documents/redhat/tools/redhat.ren/
docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/redhat.ren/fullchain4.pem redhat.ren.crt
cp ./etc/archive/redhat.ren/privkey4.pem redhat.ren.key

cd /Users/wzh/Documents/redhat/tools/ocpsc.redhat.ren/
docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/ocpsc.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/ocpsc.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.ocpsc.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/ocpsc.redhat.ren/fullchain1.pem ocpsc.redhat.ren.crt
cp ./etc/archive/ocpsc.redhat.ren/privkey1.pem ocpsc.redhat.ren.key


cd /Users/wzh/Documents/redhat/tools/apps.ocpsc.redhat.ren/
docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/apps.ocpsc.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/apps.ocpsc.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.apps.ocpsc.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/apps.ocpsc.redhat.ren/fullchain1.pem apps.ocpsc.redhat.ren.crt
cp ./etc/archive/apps.ocpsc.redhat.ren/privkey1.pem apps.ocpsc.redhat.ren.key

# scp these keys to helper
# /data/cert/*

####################################################
# on helper node
yum -y install podman docker-distribution pigz skopeo httpd-tools

# https://access.redhat.com/solutions/3175391
htpasswd -cbB /etc/docker-distribution/registry_passwd admin ***************

cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /data/registry
    delete:
        enabled: true
http:
    addr: :5443
    tls:
       certificate: /data/cert/redhat.ren.crt
       key: /data/cert/redhat.ren.key
auth:
  htpasswd:
    realm: basic‑realm
    path: /etc/docker-distribution/registry_passwd
EOF
# systemctl restart docker
systemctl stop docker-distribution
systemctl enable docker-distribution
systemctl restart docker-distribution
# 

firewall-cmd --permanent --add-port=5443/tcp
firewall-cmd --reload

podman login registry.redhat.ren:5443 -u admin -p *******************

yum install -y docker
systemctl start docker
docker login registry.redhat.ren:5443 -u admin

# upload vars-static.yaml to helper
yum -y install ansible-2.8.10 git unzip podman python36

cd /data/ocp4/ocp4-upi-helpernode
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

# upload install-config.yaml to helper /data/ocp4
cd /data/ocp4

/bin/rm -rf *.ign .openshift_install_state.json auth bootstrap master0 master1 master2 worker0 worker1 worker2

openshift-install create ignition-configs --dir=/data/ocp4

/bin/cp -f bootstrap.ign /var/www/html/ignition/bootstrap-static.ign
/bin/cp -f master.ign /var/www/html/ignition/master-0.ign
/bin/cp -f master.ign /var/www/html/ignition/master-1.ign
/bin/cp -f master.ign /var/www/html/ignition/master-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-2.ign

chmod 644 /var/www/html/ignition/*

########################################################
# on helper node, create iso
yum -y install genisoimage libguestfs-tools
systemctl start libvirtd

export NGINX_DIRECTORY=/data/ocp4
export RHCOSVERSION=4.3.0
export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.iso | awk '/Volume id/ { print $3 }')
TEMPDIR=$(mktemp -d)
echo $VOLID
echo $TEMPDIR

cd ${TEMPDIR}
# Extract the ISO content using guestfish (to avoid sudo mount)
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.iso \
  -m /dev/sda tar-out / - | tar xvf -

# Helper function to modify the config files
modify_cfg(){
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    # Append the proper image and ignition urls
    sed -e '/coreos.inst=yes/s|$| coreos.inst.install_dev=vda coreos.inst.image_url='"${URL}"'\/install\/'"${BIOSMODE}"'.raw.gz coreos.inst.ignition_url='"${URL}"'\/ignition\/'"${NODE}"'.ign ip='"${IP}"'::'"${GATEWAY}"':'"${NETMASK}"':'"${FQDN}"':'"${NET_INTERFACE}"':none:'"${DNS}"' nameserver='"${DNS}"'|' ${file} > $(pwd)/${NODE}_${file##*/}
    # Boot directly in the installation
    sed -i -e 's/default vesamenu.c32/default linux/g' -e 's/timeout 600/timeout 10/g' $(pwd)/${NODE}_${file##*/}
  done
}

URL="http://117.177.241.16:8080/"
GATEWAY="117.177.241.1"
NETMASK="255.255.255.0"
DNS="117.177.241.16"

# BOOTSTRAP
# TYPE="bootstrap"
NODE="bootstrap-static"
IP="117.177.241.243"
FQDN="vm-bootstrap"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTERS
# TYPE="master"
# MASTER-0
NODE="master-0"
IP="117.177.241.240"
FQDN="vm-master0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-1
NODE="master-1"
IP="117.177.241.241"
FQDN="vm-master1"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-2
NODE="master-2"
IP="117.177.241.242"
FQDN="vm-master2"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# WORKERS
NODE="worker-0"
IP="117.177.241.244"
FQDN="vm-worker0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-1"
IP="117.177.241.245"
FQDN="vm-worker1"
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
cd /data/ocp4
rm -Rf ${TEMPDIR}

cd ${NGINX_DIRECTORY}

# mkdir -p /data/ocp4
# mkdir -p /data/kvm
scp master-*.iso root@117.177.241.17:/data/ocp4/

scp master-*.iso root@117.177.241.21:/data/ocp4/
scp worker-*.iso root@117.177.241.21:/data/ocp4/
scp bootstrap-*.iso root@117.177.241.21:/data/ocp4/

scp master-*.iso root@117.177.241.18:/data/ocp4/

# after you create and boot master vm, worker vm, you can track the result
export KUBECONFIG=/data/ocp4/auth/kubeconfig
echo "export KUBECONFIG=/data/ocp4/auth/kubeconfig" >> ~/.bashrc
source ~/.bashrc
oc get nodes

openshift-install wait-for bootstrap-complete --log-level debug

oc get csr

openshift-install wait-for install-complete

bash add.image.load.sh /data_ssd/is.samples/mirror_dir/

oc apply -f ./99-worker-zzz-container-registries.yaml -n openshift-config
oc apply -f ./99-master-zzz-container-registries.yaml -n openshift-config

```

### helper node day1 oper

```bash

# https://docs.openshift.com/container-platform/4.3/openshift_images/managing_images/using-image-pull-secrets.html#images-update-global-pull-secret_using-image-pull-secrets
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=/data/pull-secret.json

# https://docs.openshift.com/container-platform/4.3/networking/ingress-operator.html#nw-ingress-controller-tls-profiles_configuring-ingress
oc --namespace openshift-ingress-operator get ingresscontrollers

oc --namespace openshift-ingress create secret tls custom-certs-default --cert=/data/cert/apps.ocpsc.redhat.ren.crt --key=/data/cert/apps.ocpsc.redhat.ren.key

oc patch --type=merge --namespace openshift-ingress-operator ingresscontrollers/default \
  --patch '{"spec":{"defaultCertificate":{"name":"custom-certs-default"}}}'

oc get --namespace openshift-ingress-operator ingresscontrollers/default \
  --output jsonpath='{.spec.defaultCertificate}'

##################################################3
# add rhel hw node, and remove vm worker node
ssh-copy-id root@infra-0.ocpsc.redhat.ren
ssh root@infra-0.ocpsc.redhat.ren

ssh-copy-id root@infra-1.ocpsc.redhat.ren
ssh root@infra-1.ocpsc.redhat.ren

# disable firewalld on infra-0, infra-1

yum -y install openshift-ansible openshift-clients jq

# create rhel-ansible-host
cat <<EOF > /data/ocp4/rhel-ansible-host
[all:vars]
ansible_user=root 
#ansible_become=True 

openshift_kubeconfig_path="/data/ocp4/auth/kubeconfig" 

[new_workers] 
infra-0.ocpsc.redhat.ren
infra-1.ocpsc.redhat.ren

EOF

ansible-playbook -i /data/ocp4/rhel-ansible-host /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml

# then remove old vm-worker0, vm-worker1
oc get nodes -o wide
oc adm cordon vm-worker-0.ocpsc.redhat.ren
oc adm cordon vm-worker-1.ocpsc.redhat.ren
oc adm drain vm-worker-0.ocpsc.redhat.ren --force --delete-local-data --ignore-daemonsets
oc adm drain vm-worker-1.ocpsc.redhat.ren --force --delete-local-data --ignore-daemonsets  
oc delete nodes vm-worker-0.ocpsc.redhat.ren
oc delete nodes vm-worker-1.ocpsc.redhat.ren
oc get nodes -o wide

# create nfs storage and enable image operator
bash ocp4-upi-helpernode/files/nfs-provisioner-setup.sh

oc patch configs.imageregistry.operator.openshift.io cluster -p '{"spec":{"managementState": "Managed","storage":{"pvc":{"claim":""}}}}' --type=merge

# create operator catalog
oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

cat <<EOF > redhat-operator-catalog.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: Redhat Operator Catalog
  sourceType: grpc
  image: registry.redhat.ren:5443/docker.io/wangzheng422/operator-catalog:redhat-2020-03-23
  publisher: Red Hat
EOF
oc create -f redhat-operator-catalog.yaml

# create infra node
# https://access.redhat.com/solutions/4287111
oc get node

oc label node infra0.hsc.redhat.ren node-role.kubernetes.io/infra=""
oc label node infra1.hsc.redhat.ren node-role.kubernetes.io/infra=""

oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec":{"nodePlacement":{"nodeSelector": {"matchLabels":{"node-role.kubernetes.io/infra":""}}}}}'

oc patch configs.imageregistry.operator.openshift.io/cluster -n openshift-image-registry --type=merge --patch '{"spec":{"nodeSelector":{"node-role.kubernetes.io/infra":""}}}'

oc get pod -o wide -n openshift-image-registry --sort-by=".spec.nodeName"

cat <<EOF > /data/ocp4/monitoring-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |+
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      volumeClaimTemplate:
        metadata:
          name: localpvc
        spec:
          storageClassName: local-sc
          resources:
            requests:
              storage: 400Gi
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
EOF

oc apply -f /data/ocp4/monitoring-cm.yaml -n openshift-monitoring

oc get pods -n openshift-monitoring -o wide --sort-by=".spec.nodeName"

###########################################
## add user for zte
cd /data/ocp4
touch /data/ocp4/htpasswd
htpasswd -B /data/ocp4/htpasswd zteca
htpasswd -B /data/ocp4/htpasswd zteadm

oc create secret generic htpasswd --from-file=/data/ocp4/htpasswd -n openshift-config

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

watch oc get pod -n openshift-authentication

oc adm policy add-cluster-role-to-user cluster-admin  zteca

oc new-project zte
oc adm policy add-role-to-user admin zteadm -n zte

oc get clusterrolebinding.rbac

oc get clusterrole.rbac

oc adm policy add-cluster-role-to-user cluster-reader  zteadm
oc adm policy remove-cluster-role-from-user cluster-reader  zteadm

#########################################
# add more rhel-ansible-host

# scp vars_static.yaml to helper
cd /data/ocp4/ocp4-upi-helpernode
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

ssh-copy-id root@worker-0.ocpsc.redhat.ren

cat <<EOF > /data/ocp4/rhel-ansible-host
[all:vars]
ansible_user=root 
#ansible_become=True 

openshift_kubeconfig_path="/data/ocp4/auth/kubeconfig" 

[workers] 
infra-0.ocpsc.redhat.ren
infra-1.ocpsc.redhat.ren

[new_workers]
worker-0.ocpsc.redhat.ren

EOF

ansible-playbook -i /data/ocp4/rhel-ansible-host /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml

#########################################
# add more rhel-ansible-host
cat << EOF  > /etc/yum/pluginconf.d/subscription-manager.conf
[main]
enabled=0
EOF
# scp vars_static.yaml to helper
cd /data/ocp4/ocp4-upi-helpernode
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

ssh-copy-id root@worker-1.ocpsc.redhat.ren
ssh-copy-id root@worker-2.ocpsc.redhat.ren

cat <<EOF > /data/ocp4/rhel-ansible-host
[all:vars]
ansible_user=root 
#ansible_become=True 

openshift_kubeconfig_path="/data/ocp4/auth/kubeconfig" 

[workers] 
infra-0.ocpsc.redhat.ren
infra-1.ocpsc.redhat.ren
worker-0.ocpsc.redhat.ren

[new_workers]
worker-1.ocpsc.redhat.ren
worker-2.ocpsc.redhat.ren

EOF

ansible-playbook -i /data/ocp4/rhel-ansible-host /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml


#########################################
# add worker-3 rhel-ansible-host
# upload vars-static.yaml 
cd /data/ocp4/ocp4-upi-helpernode
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

cat << EOF  > /etc/yum/pluginconf.d/subscription-manager.conf
[main]
enabled=0
EOF
# scp vars_static.yaml to helper
cd /data/ocp4/ocp4-upi-helpernode
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

ssh-copy-id root@worker-3.ocpsc.redhat.ren

cat <<EOF > /data/ocp4/rhel-ansible-host
[all:vars]
ansible_user=root 
#ansible_become=True 

openshift_kubeconfig_path="/data/ocp4/auth/kubeconfig" 

[workers] 
infra-0.ocpsc.redhat.ren
infra-1.ocpsc.redhat.ren
worker-0.ocpsc.redhat.ren
worker-1.ocpsc.redhat.ren
worker-2.ocpsc.redhat.ren

[new_workers]
worker-3.ocpsc.redhat.ren

EOF

ansible-playbook -i /data/ocp4/rhel-ansible-host /usr/share/ansible/openshift-ansible/playbooks/scaleup.yml


```

### helper node day 2 sec

```bash

cat << EOF > wzh.script
#!/bin/bash

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -s 127.0.0.1/32 -j ACCEPT
iptables -A INPUT -s 223.87.20.0/24 -j ACCEPT
iptables -A INPUT -s 117.177.241.0/24 -j ACCEPT
iptables -A INPUT -s 39.134.200.0/24 -j ACCEPT
iptables -A INPUT -s 39.134.201.0/24 -j ACCEPT
iptables -A INPUT -s 39.137.101.0/24 -j ACCEPT
iptables -A INPUT -s 192.168.7.0/24 -j ACCEPT
iptables -A INPUT -s 112.44.102.224/27 -j ACCEPT
iptables -A INPUT -s 47.93.86.113/32 -j ACCEPT
iptables -A INPUT -s 39.134.204.0/24 -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

var_local=$(cat ./wzh.script | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(''.join(sys.stdin.readlines())))"  )

cat <<EOF > 45-wzh-service.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 45-wzh-service
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - contents:
          source: data:text/plain,${var_local}
          verification: {}
        filesystem: root
        mode: 0755
        path: /etc/rc.d/wzh.local
    systemd:
      units:
      - name: wzh.service
        enabled: true
        contents: |
          [Unit]
          Description=/etc/rc.d/wzh.local Compatibility
          Documentation=zhengwan@redhat.com
          ConditionFileIsExecutable=/etc/rc.d/wzh.local
          After=network.target

          [Service]
          Type=oneshot
          User=root
          Group=root
          ExecStart=/bin/bash -c /etc/rc.d/wzh.local

          [Install]
          WantedBy=multi-user.target

EOF
oc apply -f 45-wzh-service.yaml -n openshift-config


```



### helper node quay
```bash
# on helper node
firewall-cmd --permanent --zone=public --add-port=4443/tcp
firewall-cmd --reload

podman pod create --infra-image registry.redhat.ren:5443/gcr.io/google_containers/pause-amd64:3.0 --name quay -p 4443:8443 

cd /data
rm -rf /data/quay
podman run -d --name quay-fs --entrypoint "tail" registry.redhat.ren:5443/docker.io/wangzheng422/quay-fs:3.2.0-init -f /dev/null
podman cp quay-fs:/quay.tgz /data/
tar zxf quay.tgz
podman rm -fv quay-fs

export MYSQL_CONTAINER_NAME=quay-mysql
export MYSQL_DATABASE=enterpriseregistrydb
export MYSQL_PASSWORD=zvbk3fzp5f5m2a8j
export MYSQL_USER=quayuser
export MYSQL_ROOT_PASSWORD=q98u335musckfqxe

podman run \
    --detach \
    --restart=always \
    --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
    --env MYSQL_USER=${MYSQL_USER} \
    --env MYSQL_PASSWORD=${MYSQL_PASSWORD} \
    --env MYSQL_DATABASE=${MYSQL_DATABASE} \
    --name ${MYSQL_CONTAINER_NAME} \
    --privileged=true \
    --pod quay \
    -v /data/quay/lib/mysql:/var/lib/mysql/data:Z \
    registry.redhat.ren:5443/registry.access.redhat.com/rhscl/mysql-57-rhel7

podman run -d --restart=always \
    --pod quay \
    --privileged=true \
    --name quay-redis \
    -v  /data/quay/lib/redis:/var/lib/redis/data:Z \
    registry.redhat.ren:5443/registry.access.redhat.com/rhscl/redis-32-rhel7

sleep 10

/bin/cp -f /data/cert/redhat.ren.crt /data/quay/config/extra_ca_certs/redhat.ren.crt
/bin/cp -f /data/cert/redhat.ren.crt /data/quay/config/ssl.cert
/bin/cp -f /data/cert/redhat.ren.key /data/quay/config/ssl.key

podman run --restart=always \
    --sysctl net.core.somaxconn=4096 \
    --privileged=true \
    --name quay-master \
    --pod quay \
    --add-host mysql:127.0.0.1 \
    --add-host redis:127.0.0.1 \
    --add-host clair:127.0.0.1 \
    -v /data/quay/config:/conf/stack:Z \
    -v /data/quay/storage:/datastorage:Z \
    -d registry.redhat.ren:5443/quay.io/redhat/quay:v3.2.1

# https://registry.redhat.ren:4443/

podman run --name clair-postgres --pod quay \
    -v /data/quay/lib/postgresql/data:/var/lib/postgresql/data:Z \
    -d registry.redhat.ren:5443/docker.io/library/postgres

# change /data/quay/clair-config/config.yaml
# https://registry.redhat.ren:4443 -> https://registry.redhat.ren:8443
podman run --restart=always -d \
    --name clair \
    -v /data/quay/clair-config:/clair/config:Z \
    -v /data/quay/clair-config/ca.crt:/etc/pki/ca-trust/source/anchors/ca.crt  \
    --pod quay \
    registry.redhat.ren:5443/quay.io/redhat/clair-jwt:v3.2.1

# stop and restart
podman stop clair
podman stop clair-postgres
podman stop quay-master
podman stop quay-redis
podman stop quay-mysql

podman rm quay-master
podman rm quay-redis
podman rm quay-mysql

podman rm clair
podman rm clair-postgres

podman pod ps
podman pod stop quay
podman pod rm quay

```

### helper node zte oper

```bash
cd /data/ocp4/zte

oc project zxcdn
oc adm policy add-role-to-user admin zteadm -n zxcdn

oc create serviceaccount -n zxcdn zxcdn-app
oc adm policy add-scc-to-user privileged -z zxcdn-app -n zxcdn

# oc adm policy remove-scc-from-user privileged -z  zxcdn-app

oc get networks.operator.openshift.io cluster -o yaml

oc apply -f zte-macvlan.yaml

oc apply -f slbl7-configmap.yaml  
# oc apply -f slbl7-deployment.yaml 
oc apply -f slbl7-pod.yaml

oc apply -f ottcache-configmap.yaml  
oc apply -f ottcache-pod.yaml

# oc apply -f ott-service.yaml

oc delete -f slbl7-pod.yaml
oc delete -f ottcache-pod.yaml

## web cache
oc apply -f slb-configmap.yaml  
oc apply -f slb-deployment.yaml

oc delete -f slb-deployment.yaml

oc apply -f webcache-configmap.yaml  
oc apply -f webcache-deployment.yaml

oc delete -f webcache-deployment.yaml

```

### helper host add vm-router
```bash

cd /data/ocp4/ocp4-upi-helpernode
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/config.files.yml

# upload install-config.yaml to helper /data/ocp4
cd /data/ocp4

/bin/cp -f worker.ign /var/www/html/ignition/router-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-3.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-4.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-5.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-6.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-7.ign
/bin/cp -f worker.ign /var/www/html/ignition/router-8.ign

chmod 644 /var/www/html/ignition/*


export NGINX_DIRECTORY=/data/ocp4
export RHCOSVERSION=4.3.0
export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.iso | awk '/Volume id/ { print $3 }')
TEMPDIR=$(mktemp -d)
echo $VOLID
echo $TEMPDIR

cd ${TEMPDIR}
# Extract the ISO content using guestfish (to avoid sudo mount)
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.iso \
  -m /dev/sda tar-out / - | tar xvf -

# Helper function to modify the config files
modify_cfg(){
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    # Append the proper image and ignition urls
    sed -e '/coreos.inst=yes/s|$| coreos.inst.install_dev=vda coreos.inst.image_url='"${URL}"'\/install\/'"${BIOSMODE}"'.raw.gz coreos.inst.ignition_url='"${URL}"'\/ignition\/'"${NODE}"'.ign ip='"${IP}"'::'"${GATEWAY}"':'"${NETMASK}"':'"${FQDN}"':'"${NET_INTERFACE}"':none:'"${DNS}"' nameserver='"${DNS}"'|' ${file} > $(pwd)/${NODE}_${file##*/}
    # Boot directly in the installation
    sed -i -e 's/default vesamenu.c32/default linux/g' -e 's/timeout 600/timeout 10/g' $(pwd)/${NODE}_${file##*/}
  done
}

URL="http://117.177.241.16:8080/"
GATEWAY="117.177.241.1"
NETMASK="255.255.255.0"
DNS="117.177.241.16"

NODE="router-0"
IP="117.177.241.243"
FQDN="vm-router-0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-1"
IP="117.177.241.244"
FQDN="vm-router-1"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-2"
IP="117.177.241.245"
FQDN="vm-router-2"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-3"
IP="117.177.241.246"
FQDN="vm-router-3"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-4"
IP="117.177.241.247"
FQDN="vm-router-4"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-5"
IP="117.177.241.248"
FQDN="vm-router-5"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-6"
IP="117.177.241.249"
FQDN="vm-router-6"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-7"
IP="117.177.241.250"
FQDN="vm-router-7"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="router-8"
IP="117.177.241.251"
FQDN="vm-router-8"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# Generate the images, one per node as the IP configuration is different...
# https://github.com/coreos/coreos-assembler/blob/master/src/cmd-buildextend-installer#L97-L103
for node in router-0 router-1 router-2 router-3 router-4 router-5 router-6 router-7 router-8; do
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
cd /data/ocp4
rm -Rf ${TEMPDIR}

cd ${NGINX_DIRECTORY}

scp router-*.iso root@117.177.241.21:/data/ocp4/

# after vm on bootstrap created
oc get csr
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve

oc label node vm-router-0.ocpsc.redhat.ren node-role.kubernetes.io/router=''
oc label node vm-router-1.ocpsc.redhat.ren node-role.kubernetes.io/router=''
oc label node vm-router-2.ocpsc.redhat.ren node-role.kubernetes.io/router=''
oc label node vm-router-3.ocpsc.redhat.ren node-role.kubernetes.io/router=''
oc label node vm-router-4.ocpsc.redhat.ren node-role.kubernetes.io/router=''
# oc label node vm-router-5.ocpsc.redhat.ren node-role.kubernetes.io/router=''
# oc label node vm-router-6.ocpsc.redhat.ren node-role.kubernetes.io/router=''
# oc label node vm-router-7.ocpsc.redhat.ren node-role.kubernetes.io/router=''
# oc label node vm-router-8.ocpsc.redhat.ren node-role.kubernetes.io/router=''

##########################
## secure the router vm

cat << EOF > router.mcp.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: router
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,router]}
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/router: ""
EOF
oc apply -f router.mcp.yaml

cat << EOF > wzh.script
#!/bin/bash

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -s 127.0.0.1/32 -j ACCEPT
iptables -A INPUT -s 223.87.20.0/24 -j ACCEPT
iptables -A INPUT -s 117.177.241.0/24 -j ACCEPT
iptables -A INPUT -s 39.134.200.0/24 -j ACCEPT
iptables -A INPUT -s 39.134.201.0/24 -j ACCEPT
iptables -A INPUT -s 39.137.101.0/24 -j ACCEPT
iptables -A INPUT -s 192.168.7.0/24 -j ACCEPT
iptables -A INPUT -s 112.44.102.224/27 -j ACCEPT
iptables -A INPUT -s 47.93.86.113/32 -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

var_local=$(cat ./wzh.script | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(''.join(sys.stdin.readlines())))"  )

cat <<EOF > 45-router-wzh-service.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: router
  name: 45-router-wzh-service
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - contents:
          source: data:text/plain,${var_local}
          verification: {}
        filesystem: root
        mode: 0755
        path: /etc/rc.d/wzh.local
    systemd:
      units:
      - name: wzh.service
        enabled: true
        contents: |
          [Unit]
          Description=/etc/rc.d/wzh.local Compatibility
          Documentation=zhengwan@redhat.com
          ConditionFileIsExecutable=/etc/rc.d/wzh.local
          After=network.target

          [Service]
          Type=oneshot
          User=root
          Group=root
          ExecStart=/bin/bash -c /etc/rc.d/wzh.local

          [Install]
          WantedBy=multi-user.target

EOF
oc apply -f 45-router-wzh-service.yaml -n openshift-config

# DO NOT
# cp 99-master-zzz-container-registries.yaml 99-router-zzz-container-registries.yaml 
# # change: machineconfiguration.openshift.io/role: router
# oc apply -f ./99-router-zzz-container-registries.yaml -n openshift-config

# on helper node
cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /data/registry
    delete:
        enabled: true
http:
    addr: :5443
    tls:
       certificate: /data/cert/redhat.ren.crt
       key: /data/cert/redhat.ren.key

EOF

systemctl restart docker-distribution


```

### helper node zte tcp-router
```bash

oc project openshift-ingress

# install the tcp-router and demo
oc create configmap customrouter-wzh --from-file=haproxy-config.template
oc apply -f haproxy.router.yaml

oc project zxcdn

oc apply -f ott-service.tcp.route.yaml


```

### helper node cluster tunning
```bash
# tunning for pid.max

oc label mcp worker custom-kubelet-pod-pids-limit=true

cat << EOF > PodPidsLimit.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: pod-pids-limit
spec:
  machineConfigPoolSelector:
    matchLabels:
      custom-kubelet-pod-pids-limit: 'true'
  kubeletConfig:
    PodPidsLimit: 4096
EOF
oc apply -f PodPidsLimit.yaml

cat << EOF > crio.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: ContainerRuntimeConfig
metadata:
 name: set-log-and-pid
spec:
 machineConfigPoolSelector:
   matchLabels:
     custom-kubelet-pod-pids-limit: 'true'
 containerRuntimeConfig:
   pidsLimit: 10240
EOF
oc apply -f crio.yaml


```

### helper node local storage 
https://docs.openshift.com/container-platform/4.3/storage/persistent_storage/persistent-storage-local.html
```bash

oc new-project local-storage


apiVersion: "local.storage.openshift.io/v1"
kind: "LocalVolume"
metadata:
  name: "local-disks"
  namespace: "local-storage" 
spec:
  nodeSelector: 
    nodeSelectorTerms:
    - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - infra0.hsc.redhat.ren
          - infra1.hsc.redhat.ren
  storageClassDevices:
    - storageClassName: "local-sc"
      volumeMode: Filesystem 
      fsType: xfs 
      devicePaths: 
        - /dev/datavg/monitorlv


```

### bootstrap node day1

```bash
##########################################################3
## on bootstrap
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

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

brctl show
virsh net-list

cat << EOF >  /data/virt-net.xml
<network>
  <name>br0</name>
  <forward mode='bridge'>
    <bridge name='br0'/>
  </forward>
</network>
EOF

virsh net-define --file virt-net.xml
virsh net-dumpxml br0
# virsh net-undefine openshift4
# virsh net-destroy openshift4
virsh net-autostart br0
virsh net-start br0

cp /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-em1.orig

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=em1
DEVICE=em1
ONBOOT=yes
# IPADDR=117.177.241.21
# PREFIX=24
# GATEWAY=117.177.241.1
IPV6_PRIVACY=no
# DNS1=117.177.241.16
BRIDGE=br0
EOF

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-br0 
TYPE=Bridge
BOOTPROTO=static
IPADDR=117.177.241.21
GATEWAY=117.177.241.1
DNS1=117.177.241.16
ONBOOT=yes
DEFROUTE=yes
NAME=br0
DEVICE=br0
PREFIX=24
EOF

systemctl restart network

virt-install --name=ocp4-bootstrap --vcpus=2 --ram=16384 \
--disk path=/data/kvm/ocp4-bootstrap.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/bootstrap-static.iso   

virt-install --name=ocp4-master0 --vcpus=8 --ram=65536 \
--disk path=/data/kvm/ocp4-master0.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/master-0.iso 

# virt-install --name=ocp4-master1 --vcpus=20 --ram=200704 \
# --disk path=/data/kvm/ocp4-master1.qcow2,bus=virtio,size=200 \
# --os-variant rhel8.0 --network bridge=br0,model=virtio \
# --boot menu=on --cdrom /data/ocp4/master-1.iso 

virt-install --name=ocp4-master2 --vcpus=8 --ram=65536 \
--disk path=/data/kvm/ocp4-master2.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/master-2.iso 

virt-install --name=ocp4-worker0 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-worker0.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/worker-0.iso 

virt-install --name=ocp4-worker1 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-worker1.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/worker-1.iso 


tar -cvf - ocp4-master0.qcow2 | pigz -c > /data/kvm/ocp4-master0.qcow2.tgz
rsync -e "ssh -c chacha20-poly1305@openssh.com" --info=progress2 -P -arz  /data/kvm/ocp4-master0.qcow2.tgz root@117.177.241.18:/data/kvm/

tar -cvf - ocp4-master2.qcow2 | pigz -c > /data/kvm/ocp4-master2.qcow2.tgz
rsync -e "ssh -c chacha20-poly1305@openssh.com" --info=progress2 -P -arz  /data/kvm/ocp4-master2.qcow2.tgz root@117.177.241.22:/data/kvm/

# anti scan
firewall-cmd --permanent --new-ipset=my-allow-list --type=hash:net
firewall-cmd --permanent --get-ipsets

cat > /root/iplist.txt <<EOL
127.0.0.1/32
223.87.20.0/24
117.177.241.0/24
39.134.200.0/24
39.134.201.0/24
39.137.101.0/24
192.168.7.0/24
112.44.102.224/27
47.93.86.113/32
EOL

firewall-cmd --permanent --ipset=my-allow-list --add-entries-from-file=iplist.txt

firewall-cmd --permanent --ipset=my-allow-list --get-entries

firewall-cmd --permanent --zone=trusted --add-source=ipset:my-allow-list 
firewall-cmd --reload

firewall-cmd --list-all
firewall-cmd --get-active-zones

firewall-cmd --set-default-zone=block
firewall-cmd --runtime-to-permanent
firewall-cmd --reload

# https://access.redhat.com/solutions/39604
virsh list

virsh dump ocp4-router-0 /data/tmp/ocp4-router-0.dump --memory-only --verbose

virsh dump ocp4-router-1 /data/tmp/ocp4-router-1.dump --memory-only --verbose

virsh dump ocp4-router-2 /data/tmp/ocp4-router-2.dump --memory-only --verbose

virsh dump ocp4-router-3 /data/tmp/ocp4-router-3.dump --memory-only --verbose

cd /data
tar -cvf - tmp/ | pigz -c > virsh.dump.tgz



################################
## add more router vm
virt-install --name=ocp4-router-0 --vcpus=4 --ram=16384 \
--disk path=/data/kvm/ocp4-router-0.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/router-0.iso 

virt-install --name=ocp4-router-1 --vcpus=4 --ram=16384 \
--disk path=/data/kvm/ocp4-router-1.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/router-1.iso 

virt-install --name=ocp4-router-2 --vcpus=4 --ram=16384 \
--disk path=/data/kvm/ocp4-router-2.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/router-2.iso 

virt-install --name=ocp4-router-3 --vcpus=4 --ram=16384 \
--disk path=/data/kvm/ocp4-router-3.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/router-3.iso 

virt-install --name=ocp4-router-4 --vcpus=4 --ram=16384 \
--disk path=/data/kvm/ocp4-router-4.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/router-4.iso 

# virt-install --name=ocp4-router-5 --vcpus=2 --ram=8192 \
# --disk path=/data/kvm/ocp4-router-5.qcow2,bus=virtio,size=200 \
# --os-variant rhel8.0 --network bridge=br0,model=virtio \
# --boot menu=on --cdrom /data/ocp4/router-5.iso 

# virt-install --name=ocp4-router-6 --vcpus=2 --ram=8192 \
# --disk path=/data/kvm/ocp4-router-6.qcow2,bus=virtio,size=200 \
# --os-variant rhel8.0 --network bridge=br0,model=virtio \
# --boot menu=on --cdrom /data/ocp4/router-6.iso 

# virt-install --name=ocp4-router-7 --vcpus=2 --ram=8192 \
# --disk path=/data/kvm/ocp4-router-7.qcow2,bus=virtio,size=200 \
# --os-variant rhel8.0 --network bridge=br0,model=virtio \
# --boot menu=on --cdrom /data/ocp4/router-7.iso 

# virt-install --name=ocp4-router-8 --vcpus=2 --ram=8192 \
# --disk path=/data/kvm/ocp4-router-8.qcow2,bus=virtio,size=200 \
# --os-variant rhel8.0 --network bridge=br0,model=virtio \
# --boot menu=on --cdrom /data/ocp4/router-8.iso 


# helper node operation


```

### master1 node day1

```bash
##########################################################3
## on master1
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

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

brctl show
virsh net-list

cat << EOF >  /data/virt-net.xml
<network>
  <name>br0</name>
  <forward mode='bridge'>
    <bridge name='br0'/>
  </forward>
</network>
EOF

virsh net-define --file virt-net.xml
virsh net-dumpxml br0
# virsh net-undefine openshift4
# virsh net-destroy openshift4
virsh net-autostart br0
virsh net-start br0

cp /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-em1.orig

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=em1
DEVICE=em1
ONBOOT=yes
# IPADDR=117.177.241.17
# PREFIX=24
# GATEWAY=117.177.241.1
IPV6_PRIVACY=no
# DNS1=117.177.241.16
BRIDGE=br0
EOF

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-br0 
TYPE=Bridge
BOOTPROTO=static
IPADDR=117.177.241.17
GATEWAY=117.177.241.1
DNS1=117.177.241.16
ONBOOT=yes
DEFROUTE=yes
NAME=br0
DEVICE=br0
PREFIX=24
EOF

systemctl restart network

virt-install --name=ocp4-master1 --vcpus=20 --ram=200704 \
--disk path=/data/kvm/ocp4-master1.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on --cdrom /data/ocp4/master-1.iso 

virsh list --all

virsh start ocp4-master1

# anti scan
firewall-cmd --permanent --new-ipset=my-allow-list --type=hash:net
firewall-cmd --permanent --get-ipsets

cat > /root/iplist.txt <<EOL
127.0.0.1/32
223.87.20.0/24
117.177.241.0/24
39.134.200.0/24
39.134.201.0/24
39.137.101.0/24
192.168.7.0/24
112.44.102.224/27
47.93.86.113/32
EOL

firewall-cmd --permanent --ipset=my-allow-list --add-entries-from-file=iplist.txt

firewall-cmd --permanent --ipset=my-allow-list --get-entries

firewall-cmd --permanent --zone=trusted --add-source=ipset:my-allow-list 
firewall-cmd --reload

firewall-cmd --list-all
firewall-cmd --get-active-zones

firewall-cmd --set-default-zone=block
firewall-cmd --runtime-to-permanent
firewall-cmd --reload

```

### master0 node day1

```bash
########################################################
# master0 
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

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

brctl show
virsh net-list

cat << EOF >  /data/virt-net.xml
<network>
  <name>br0</name>
  <forward mode='bridge'>
    <bridge name='br0'/>
  </forward>
</network>
EOF

virsh net-define --file virt-net.xml
virsh net-dumpxml br0
# virsh net-undefine openshift4
# virsh net-destroy openshift4
virsh net-autostart br0
virsh net-start br0

cp /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-em1.orig

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=em1
DEVICE=em1
ONBOOT=yes
# IPADDR=117.177.241.18
# PREFIX=24
# GATEWAY=117.177.241.1
IPV6_PRIVACY=no
# DNS1=117.177.241.16
BRIDGE=br0
EOF

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-br0 
TYPE=Bridge
BOOTPROTO=static
IPADDR=117.177.241.18
GATEWAY=117.177.241.1
DNS1=117.177.241.16
ONBOOT=yes
DEFROUTE=yes
NAME=br0
DEVICE=br0
PREFIX=24
EOF

systemctl restart network

mkdir -p /data/ocp4
mkdir -p /data/kvm

pigz -dc ocp4-master0.qcow2.tgz | tar xf -

virt-install --name=ocp4-master0 --vcpus=20 --ram=200704 \
--disk path=/data/kvm/ocp4-master0.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on 

virsh list --all

virsh start ocp4-master0

# anti scan
firewall-cmd --permanent --new-ipset=my-allow-list --type=hash:net
firewall-cmd --permanent --get-ipsets

cat > /root/iplist.txt <<EOL
127.0.0.1/32
223.87.20.0/24
117.177.241.0/24
39.134.200.0/24
39.134.201.0/24
39.137.101.0/24
192.168.7.0/24
112.44.102.224/27
47.93.86.113/32
EOL

firewall-cmd --permanent --ipset=my-allow-list --add-entries-from-file=iplist.txt

firewall-cmd --permanent --ipset=my-allow-list --get-entries

firewall-cmd --permanent --zone=trusted --add-source=ipset:my-allow-list 
firewall-cmd --reload

firewall-cmd --list-all
firewall-cmd --get-active-zones

firewall-cmd --set-default-zone=block
firewall-cmd --runtime-to-permanent
firewall-cmd --reload

```

### master2 node day1

```bash
########################################################
# master2 
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

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

brctl show
virsh net-list

cat << EOF >  /data/virt-net.xml
<network>
  <name>br0</name>
  <forward mode='bridge'>
    <bridge name='br0'/>
  </forward>
</network>
EOF

virsh net-define --file virt-net.xml
virsh net-dumpxml br0
# virsh net-undefine openshift4
# virsh net-destroy openshift4
virsh net-autostart br0
virsh net-start br0

cp /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-em1.orig

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=em1
DEVICE=em1
ONBOOT=yes
# IPADDR=117.177.241.22
# PREFIX=24
# GATEWAY=117.177.241.1
IPV6_PRIVACY=no
# DNS1=117.177.241.16
BRIDGE=br0
EOF

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-br0 
TYPE=Bridge
BOOTPROTO=static
IPADDR=117.177.241.22
GATEWAY=117.177.241.1
DNS1=117.177.241.16
ONBOOT=yes
DEFROUTE=yes
NAME=br0
DEVICE=br0
PREFIX=24
EOF

systemctl restart network

mkdir -p /data/ocp4
mkdir -p /data/kvm

pigz -dc ocp4-master2.qcow2.tgz | tar xf -

virt-install --name=ocp4-master2 --vcpus=20 --ram=200704 \
--disk path=/data/kvm/ocp4-master2.qcow2,bus=virtio,size=200 \
--os-variant rhel8.0 --network bridge=br0,model=virtio \
--boot menu=on 

virsh list --all

virsh start ocp4-master2

# anti scan
firewall-cmd --permanent --new-ipset=my-allow-list --type=hash:net
firewall-cmd --permanent --get-ipsets

cat > /root/iplist.txt <<EOL
127.0.0.1/32
223.87.20.0/24
117.177.241.0/24
39.134.200.0/24
39.134.201.0/24
39.137.101.0/24
192.168.7.0/24
112.44.102.224/27
47.93.86.113/32
EOL

firewall-cmd --permanent --ipset=my-allow-list --add-entries-from-file=iplist.txt

firewall-cmd --permanent --ipset=my-allow-list --get-entries

firewall-cmd --permanent --zone=trusted --add-source=ipset:my-allow-list 
firewall-cmd --reload

firewall-cmd --list-all
firewall-cmd --get-active-zones

firewall-cmd --set-default-zone=block
firewall-cmd --runtime-to-permanent
firewall-cmd --reload

```

### infra0 node day1

```bash
systemctl disable firewalld.service
systemctl stop firewalld.service

# secure for anti-scan
cat << EOF >> /etc/rc.local

ipset create my-allow-set hash:net
ipset add my-allow-set 127.0.0.1/32
ipset add my-allow-set 223.87.20.0/24
ipset add my-allow-set 117.177.241.0/24
ipset add my-allow-set 39.134.200.0/24
ipset add my-allow-set 39.134.201.0/24
ipset add my-allow-set 39.137.101.0/24
ipset add my-allow-set 192.168.7.0/24
ipset add my-allow-set 112.44.102.224/27
ipset add my-allow-set 47.93.86.113/32

ipset add my-allow-set 39.134.204.0/24

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m set --match-set my-allow-set src -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# systemctl restart rc-local

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

```

### infra1 node day1

```bash
systemctl disable firewalld.service
systemctl stop firewalld.service

# secure for anti-scan
cat << EOF >> /etc/rc.local

ipset create my-allow-set hash:net
ipset add my-allow-set 127.0.0.1/32
ipset add my-allow-set 223.87.20.0/24
ipset add my-allow-set 117.177.241.0/24
ipset add my-allow-set 39.134.200.0/24
ipset add my-allow-set 39.134.201.0/24
ipset add my-allow-set 39.137.101.0/24
ipset add my-allow-set 192.168.7.0/24
ipset add my-allow-set 112.44.102.224/27
ipset add my-allow-set 47.93.86.113/32

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m set --match-set my-allow-set src -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# systemctl restart rc-local

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

```

### worker-0 day2 oper

```bash

podman login registry.redhat.ren:4443 -u zteadm

# localhost/ottcache-img:6.01.05.01T03
skopeo copy docker-archive:ZXCDN-OTT-IAS-IMGV6.01.05.01_TEST.tar docker://registry.redhat.ren:4443/zteadm/ottcache-img:6.01.05.01T03

# localhost/slbl7-img:6.01.05.01T03
skopeo copy docker-archive:ZXCDN-OTT-SLBL7-IMGV6.01.05.01_TEST.tar docker://registry.redhat.ren:4443/zteadm/slbl7-img:6.01.05.01T03

# localhost/webcache-img:v6.01.04.03
skopeo copy docker-archive:ZXCDN-CACHE-WEBCACHE-IMGV6.01.04.03.tar docker://registry.redhat.ren:4443/zteadm/webcache-img:v6.01.04.03

# localhost/pg-img:v1.01.01.01
skopeo copy docker-archive:ZXCDN-PG-IMGV1.01.01.01.tar docker://registry.redhat.ren:4443/zteadm/pg-img:v1.01.01.01

# localhost/slb-img:v6.01.04.03
skopeo copy docker-archive:ZXCDN-CACHE-SLB-IMGV6.01.04.03.tar docker://registry.redhat.ren:4443/zteadm/slb-img:v6.01.04.03

# io speed test
dd if=/dev/zero of=/data/testfile bs=1G count=10
# 10+0 records in
# 10+0 records out
# 10737418240 bytes (11 GB) copied, 6.85688 s, 1.6 GB/s

dd if=/dev/zero of=/data/testfile bs=1G count=10 oflag=direct
# 10+0 records in
# 10+0 records out
# 10737418240 bytes (11 GB) copied, 3.98098 s, 2.7 GB/s

dd if=/dev/zero of=/data/testfile bs=5M count=9999
# 9999+0 records in
# 9999+0 records out
# 52423557120 bytes (52 GB) copied, 27.8529 s, 1.9 GB/s

dd if=/dev/zero of=/data/testfile bs=5M count=9999 oflag=direct
# 9999+0 records in
# 9999+0 records out
# 52423557120 bytes (52 GB) copied, 16.1121 s, 3.3 GB/s

dd if=/dev/zero of=/data/testfile bs=5M count=9999 oflag=dsync
# 9999+0 records in
# 9999+0 records out
# 52423557120 bytes (52 GB) copied, 51.2713 s, 1.0 GB/s

dd if=/data/testfile of=/dev/null bs=1M count=9999 oflag=dsync
# 9999+0 records in
# 9999+0 records out
# 10484711424 bytes (10 GB) copied, 1.9141 s, 5.5 GB/s

dd if=/data/testfile of=/dev/null bs=5M count=9999 oflag=dsync
# 9999+0 records in
# 9999+0 records out
# 52423557120 bytes (52 GB) copied, 9.3676 s, 5.6 GB/s

# secure for anti-scan
cat << EOF > /etc/rc.local
#!/bin/bash
# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
# In contrast to previous versions due to parallel execution during boot
# this script will NOT be run after all other services.
#
# Please note that you must run 'chmod +x /etc/rc.d/rc.local' to ensure
# that this script will be executed during boot.

touch /var/lock/subsys/local

ipset create my-allow-set hash:net
ipset add my-allow-set 127.0.0.1/32
ipset add my-allow-set 223.87.20.0/24
ipset add my-allow-set 117.177.241.0/24
ipset add my-allow-set 39.134.200.0/24
ipset add my-allow-set 39.134.201.0/24
ipset add my-allow-set 39.137.101.0/24
ipset add my-allow-set 192.168.7.0/24
ipset add my-allow-set 112.44.102.224/27
ipset add my-allow-set 47.93.86.113/32
ipset add my-allow-set 221.226.0.75/32
ipset add my-allow-set 210.21.236.182/32
ipset add my-allow-set 61.132.54.2/32
ipset add my-allow-set 39.134.198.0/24

ipset add my-allow-set 218.205.236.16/28

ipset add my-allow-set 39.134.204.0/24

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m set --match-set my-allow-set src -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# systemctl restart rc-local

ipset add my-allow-set 221.226.0.75/32
ipset add my-allow-set 210.21.236.182/32
ipset add my-allow-set 61.132.54.2/32

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

```

### worker-1 day2 oper

```bash
cat << EOF > /etc/rc.local
#!/bin/bash
# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
# In contrast to previous versions due to parallel execution during boot
# this script will NOT be run after all other services.
#
# Please note that you must run 'chmod +x /etc/rc.d/rc.local' to ensure
# that this script will be executed during boot.

touch /var/lock/subsys/local

ipset create my-allow-set hash:net
ipset add my-allow-set 127.0.0.1/32
ipset add my-allow-set 223.87.20.0/24
ipset add my-allow-set 117.177.241.0/24
ipset add my-allow-set 39.134.200.0/24
ipset add my-allow-set 39.134.201.0/24
ipset add my-allow-set 39.137.101.0/24
ipset add my-allow-set 192.168.7.0/24
ipset add my-allow-set 112.44.102.224/27
ipset add my-allow-set 47.93.86.113/32
ipset add my-allow-set 221.226.0.75/32
ipset add my-allow-set 210.21.236.182/32
ipset add my-allow-set 61.132.54.2/32
ipset add my-allow-set 39.134.198.0/24

ipset add my-allow-set 218.205.236.16/28

ipset add my-allow-set 39.134.204.0/24

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m set --match-set my-allow-set src -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# systemctl restart rc-local

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd

```

### worker-2 day2 oper

```bash
cat << EOF > /etc/rc.local
#!/bin/bash
# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
# In contrast to previous versions due to parallel execution during boot
# this script will NOT be run after all other services.
#
# Please note that you must run 'chmod +x /etc/rc.d/rc.local' to ensure
# that this script will be executed during boot.

touch /var/lock/subsys/local

ipset create my-allow-set hash:net
ipset add my-allow-set 127.0.0.1/32
ipset add my-allow-set 223.87.20.0/24
ipset add my-allow-set 117.177.241.0/24
ipset add my-allow-set 39.134.200.0/24
ipset add my-allow-set 39.134.201.0/24
ipset add my-allow-set 39.137.101.0/24
ipset add my-allow-set 192.168.7.0/24
ipset add my-allow-set 112.44.102.224/27
ipset add my-allow-set 47.93.86.113/32
ipset add my-allow-set 221.226.0.75/32
ipset add my-allow-set 210.21.236.182/32
ipset add my-allow-set 61.132.54.2/32
ipset add my-allow-set 39.134.198.0/24

ipset add my-allow-set 218.205.236.16/28

ipset add my-allow-set 39.134.204.0/24

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m set --match-set my-allow-set src -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A INPUT -p udp -j REJECT

EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# systemctl restart rc-local

# 配置kvm环境
yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer virt-manager

systemctl enable libvirtd
systemctl start libvirtd
systemctl status libvirtd

systemctl stop libvirtd
systemctl disable libvirtd
# Installed:
#   libguestfs-tools.noarch 1:1.40.2-5.el7_7.3          libvirt.x86_64 0:4.5.0-23.el7_7.5          libvirt-python.x86_64 0:4.5.0-1.el7
#   qemu-kvm.x86_64 10:1.5.3-167.el7_7.4                virt-install.noarch 0:1.5.0-7.el7          virt-manager.noarch 0:1.5.0-7.el7
#   virt-viewer.x86_64 0:5.0-15.el7

# Dependency Installed:
#   adwaita-cursor-theme.noarch 0:3.28.0-1.el7                            adwaita-icon-theme.noarch 0:3.28.0-1.el7
#   at-spi2-atk.x86_64 0:2.26.2-1.el7                                     at-spi2-core.x86_64 0:2.28.0-1.el7
#   atk.x86_64 0:2.28.1-1.el7                                             augeas-libs.x86_64 0:1.4.0-9.el7
#   autogen-libopts.x86_64 0:5.18-5.el7                                   cairo.x86_64 0:1.15.12-4.el7
#   cairo-gobject.x86_64 0:1.15.12-4.el7                                  cdparanoia-libs.x86_64 0:10.2-17.el7
#   celt051.x86_64 0:0.5.1.3-8.el7                                        colord-libs.x86_64 0:1.3.4-1.el7
#   cyrus-sasl.x86_64 0:2.1.26-23.el7                                     dbus-x11.x86_64 1:1.10.24-13.el7_6
#   dconf.x86_64 0:0.28.0-4.el7                                           dejavu-fonts-common.noarch 0:2.33-6.el7
#   dejavu-sans-fonts.noarch 0:2.33-6.el7                                 flac-libs.x86_64 0:1.3.0-5.el7_1
#   fontconfig.x86_64 0:2.13.0-4.3.el7                                    fontpackages-filesystem.noarch 0:1.44-8.el7
#   fribidi.x86_64 0:1.0.2-1.el7_7.1                                      fuse.x86_64 0:2.9.2-11.el7
#   fuse-libs.x86_64 0:2.9.2-11.el7                                       gdk-pixbuf2.x86_64 0:2.36.12-3.el7
#   genisoimage.x86_64 0:1.1.11-25.el7                                    glib-networking.x86_64 0:2.56.1-1.el7
#   glusterfs-api.x86_64 0:3.12.2-47.2.el7                                glusterfs-cli.x86_64 0:3.12.2-47.2.el7
#   gnome-icon-theme.noarch 0:3.12.0-1.el7                                gnutls.x86_64 0:3.3.29-9.el7_6
#   gnutls-dane.x86_64 0:3.3.29-9.el7_6                                   gnutls-utils.x86_64 0:3.3.29-9.el7_6
#   gperftools-libs.x86_64 0:2.6.1-1.el7                                  graphite2.x86_64 0:1.3.10-1.el7_3
#   gsettings-desktop-schemas.x86_64 0:3.28.0-2.el7                       gsm.x86_64 0:1.0.13-11.el7
#   gstreamer1.x86_64 0:1.10.4-2.el7                                      gstreamer1-plugins-base.x86_64 0:1.10.4-2.el7
#   gtk-update-icon-cache.x86_64 0:3.22.30-3.el7                          gtk-vnc2.x86_64 0:0.7.0-3.el7
#   gtk3.x86_64 0:3.22.30-3.el7                                           gvnc.x86_64 0:0.7.0-3.el7
#   harfbuzz.x86_64 0:1.7.5-2.el7                                         hexedit.x86_64 0:1.2.13-5.el7
#   hicolor-icon-theme.noarch 0:0.12-7.el7                                hivex.x86_64 0:1.3.10-6.9.el7
#   ipxe-roms-qemu.noarch 0:20180825-2.git133f4c.el7                      iso-codes.noarch 0:3.46-2.el7
#   jasper-libs.x86_64 0:1.900.1-33.el7                                   jbigkit-libs.x86_64 0:2.0-11.el7
#   json-glib.x86_64 0:1.4.2-2.el7                                        lcms2.x86_64 0:2.6-3.el7
#   libICE.x86_64 0:1.0.9-9.el7                                           libSM.x86_64 0:1.2.2-2.el7
#   libX11.x86_64 0:1.6.7-2.el7                                           libX11-common.noarch 0:1.6.7-2.el7
#   libXau.x86_64 0:1.0.8-2.1.el7                                         libXcomposite.x86_64 0:0.4.4-4.1.el7
#   libXcursor.x86_64 0:1.1.15-1.el7                                      libXdamage.x86_64 0:1.1.4-4.1.el7
#   libXext.x86_64 0:1.3.3-3.el7                                          libXfixes.x86_64 0:5.0.3-1.el7
#   libXft.x86_64 0:2.3.2-2.el7                                           libXi.x86_64 0:1.7.9-1.el7
#   libXinerama.x86_64 0:1.1.3-2.1.el7                                    libXmu.x86_64 0:1.1.2-2.el7
#   libXrandr.x86_64 0:1.5.1-2.el7                                        libXrender.x86_64 0:0.9.10-1.el7
#   libXt.x86_64 0:1.1.5-3.el7                                            libXtst.x86_64 0:1.2.3-1.el7
#   libXv.x86_64 0:1.0.11-1.el7                                           libXxf86misc.x86_64 0:1.0.3-7.1.el7
#   libXxf86vm.x86_64 0:1.1.4-1.el7                                       libarchive.x86_64 0:3.1.2-14.el7_7
#   libasyncns.x86_64 0:0.8-7.el7                                         libcacard.x86_64 40:2.5.2-2.el7
#   libconfig.x86_64 0:1.4.9-5.el7                                        libepoxy.x86_64 0:1.5.2-1.el7
#   libglvnd.x86_64 1:1.0.1-0.8.git5baa1e5.el7                            libglvnd-egl.x86_64 1:1.0.1-0.8.git5baa1e5.el7
#   libglvnd-glx.x86_64 1:1.0.1-0.8.git5baa1e5.el7                        libgovirt.x86_64 0:0.3.4-3.el7
#   libguestfs.x86_64 1:1.40.2-5.el7_7.3                                  libguestfs-tools-c.x86_64 1:1.40.2-5.el7_7.3
#   libgusb.x86_64 0:0.2.9-1.el7                                          libibverbs.x86_64 0:22.1-3.el7
#   libiscsi.x86_64 0:1.9.0-7.el7                                         libjpeg-turbo.x86_64 0:1.2.90-8.el7
#   libmodman.x86_64 0:2.0.1-8.el7                                        libogg.x86_64 2:1.3.0-7.el7
#   libosinfo.x86_64 0:1.1.0-3.el7                                        libproxy.x86_64 0:0.4.11-11.el7
#   librdmacm.x86_64 0:22.1-3.el7                                         libsndfile.x86_64 0:1.0.25-10.el7
#   libsoup.x86_64 0:2.62.2-2.el7                                         libthai.x86_64 0:0.1.14-9.el7
#   libtheora.x86_64 1:1.1.1-8.el7                                        libtiff.x86_64 0:4.0.3-32.el7
#   libusal.x86_64 0:1.1.11-25.el7                                        libusbx.x86_64 0:1.0.21-1.el7
#   libvirt-bash-completion.x86_64 0:4.5.0-23.el7_7.5                     libvirt-client.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon.x86_64 0:4.5.0-23.el7_7.5                              libvirt-daemon-config-network.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-config-nwfilter.x86_64 0:4.5.0-23.el7_7.5              libvirt-daemon-driver-interface.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-lxc.x86_64 0:4.5.0-23.el7_7.5                   libvirt-daemon-driver-network.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-nodedev.x86_64 0:4.5.0-23.el7_7.5               libvirt-daemon-driver-nwfilter.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-qemu.x86_64 0:4.5.0-23.el7_7.5                  libvirt-daemon-driver-secret.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-storage.x86_64 0:4.5.0-23.el7_7.5               libvirt-daemon-driver-storage-core.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-storage-disk.x86_64 0:4.5.0-23.el7_7.5          libvirt-daemon-driver-storage-gluster.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-storage-iscsi.x86_64 0:4.5.0-23.el7_7.5         libvirt-daemon-driver-storage-logical.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-storage-mpath.x86_64 0:4.5.0-23.el7_7.5         libvirt-daemon-driver-storage-rbd.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-daemon-driver-storage-scsi.x86_64 0:4.5.0-23.el7_7.5          libvirt-daemon-kvm.x86_64 0:4.5.0-23.el7_7.5
#   libvirt-glib.x86_64 0:1.0.0-1.el7                                     libvirt-libs.x86_64 0:4.5.0-23.el7_7.5
#   libvisual.x86_64 0:0.4.0-16.el7                                       libvorbis.x86_64 1:1.3.3-8.el7.1
#   libwayland-client.x86_64 0:1.15.0-1.el7                               libwayland-cursor.x86_64 0:1.15.0-1.el7
#   libwayland-egl.x86_64 0:1.15.0-1.el7                                  libwayland-server.x86_64 0:1.15.0-1.el7
#   libxcb.x86_64 0:1.13-1.el7                                            libxkbcommon.x86_64 0:0.7.1-3.el7
#   libxshmfence.x86_64 0:1.2-1.el7                                       lsof.x86_64 0:4.87-6.el7
#   lzop.x86_64 0:1.03-10.el7                                             mesa-libEGL.x86_64 0:18.3.4-6.el7_7
#   mesa-libGL.x86_64 0:18.3.4-6.el7_7                                    mesa-libgbm.x86_64 0:18.3.4-6.el7_7
#   mesa-libglapi.x86_64 0:18.3.4-6.el7_7                                 mtools.x86_64 0:4.0.18-5.el7
#   netcf-libs.x86_64 0:0.2.8-4.el7                                       nettle.x86_64 0:2.7.1-8.el7
#   numad.x86_64 0:0.5-18.20150602git.el7                                 opus.x86_64 0:1.0.2-6.el7
#   orc.x86_64 0:0.4.26-1.el7                                             osinfo-db.noarch 0:20190319-2.el7
#   osinfo-db-tools.x86_64 0:1.1.0-1.el7                                  pango.x86_64 0:1.42.4-4.el7_7
#   pcre2.x86_64 0:10.23-2.el7                                            perl-Sys-Guestfs.x86_64 1:1.40.2-5.el7_7.3
#   perl-Sys-Virt.x86_64 0:4.5.0-2.el7                                    perl-hivex.x86_64 0:1.3.10-6.9.el7
#   perl-libintl.x86_64 0:1.20-12.el7                                     pixman.x86_64 0:0.34.0-1.el7
#   pulseaudio-libs.x86_64 0:10.0-5.el7                                   pulseaudio-libs-glib2.x86_64 0:10.0-5.el7
#   pycairo.x86_64 0:1.8.10-8.el7                                         python-gobject.x86_64 0:3.22.0-1.el7_4.1
#   qemu-img.x86_64 10:1.5.3-167.el7_7.4                                  qemu-kvm-common.x86_64 10:1.5.3-167.el7_7.4
#   radvd.x86_64 0:2.17-3.el7                                             rdma-core.x86_64 0:22.1-3.el7
#   rest.x86_64 0:0.8.1-2.el7                                             scrub.x86_64 0:2.5.2-7.el7
#   seabios-bin.noarch 0:1.11.0-2.el7                                     seavgabios-bin.noarch 0:1.11.0-2.el7
#   sgabios-bin.noarch 1:0.20110622svn-4.el7                              spice-glib.x86_64 0:0.35-4.el7
#   spice-gtk3.x86_64 0:0.35-4.el7                                        spice-server.x86_64 0:0.14.0-7.el7
#   squashfs-tools.x86_64 0:4.3-0.21.gitaae0aff4.el7                      supermin5.x86_64 0:5.1.19-1.el7
#   syslinux.x86_64 0:4.05-15.el7                                         syslinux-extlinux.x86_64 0:4.05-15.el7
#   trousers.x86_64 0:0.3.14-2.el7                                        unbound-libs.x86_64 0:1.6.6-1.el7
#   usbredir.x86_64 0:0.7.1-3.el7                                         virt-manager-common.noarch 0:1.5.0-7.el7
#   vte-profile.x86_64 0:0.52.2-2.el7                                     vte291.x86_64 0:0.52.2-2.el7
#   xkeyboard-config.noarch 0:2.24-1.el7                                  xml-common.noarch 0:0.6.3-39.el7
#   xorg-x11-server-utils.x86_64 0:7.7-20.el7                             xorg-x11-xauth.x86_64 1:1.0.9-1.el7
#   xorg-x11-xinit.x86_64 0:1.3.4-2.el7                                   yajl.x86_64 0:2.0.4-4.el7

```






## tips

1. config local storage operator
2. config monitor storage
3. benchmark the storage using real senario

