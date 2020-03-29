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

fail2ban-client status
systemctl status fail2ban
tail -F /var/log/fail2ban.log

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

diff /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK

systemctl restart sshd

passwd

useradd -m wzh

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

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                   xfs     defaults        0 0

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

cp /etc/fstab /etc/fstab.bak

cat << EOF >> /etc/fstab
/dev/datavg/datalv /data                   xfs     defaults        0 0

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

```

## install ocp

### helper node

```bash
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
scp master-0.iso root@117.177.241.17:/data/ocp4/

scp master-*.iso root@117.177.241.21:/data/ocp4/
scp worker-*.iso root@117.177.241.21:/data/ocp4/
scp bootstrap-*.iso root@117.177.241.21:/data/ocp4/

```

### bootstrap node