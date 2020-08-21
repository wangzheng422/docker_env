```bash
mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=file:///root/data
enabled=1
gpgcheck=0

EOF

cat << EOF > /etc/yum/pluginconf.d/subscription-manager.conf
[main]
enabled=0

EOF

# https://access.redhat.com/articles/1282083
yum install open-vm-tools
systemctl enable vmtoolsd.service 
systemctl start vmtoolsd.service

cd
tar -cf - data/ | pigz -c > /mnt/hgfs/ocp.4.2.8/rhel-data.tgz

cd /data
tar -cf - ocp4/ | pigz -c > /mnt/hgfs/ocp.4.2.8/ocp4.tgz
tar -cf - registry/ | pigz -c > /mnt/hgfs/ocp.4.2.8/registry.tgz



# back up to disk
OCP_VERION="4.5.7"

mkdir -p /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}
ls /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}

cd /root
tar -cf - data/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}/rhel-data.tgz

cd /data
tar -cf - ocp4/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}/ocp4.tgz
tar -cf - registry/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}/registry.tgz
tar -cf - is.samples/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}/is.samples.tgz

cd /mnt/hgfs/ocp.archive/ocp.tgz.${OCP_VERION}/
split -b 5000m ocp4.tgz ocp4.
split -b 5000m registry.tgz registry.
split -b 5000m is.samples.tgz is.samples.
split -b 5000m rhel-data.tgz rhel-data.


cd 
mkdir -p /mnt/hgfs/ocp/rhel-data/
rsync --info=progress2 -P --delete -arz --no-o --no-g --no-perms /root/data/  /mnt/hgfs/ocp/rhel-data/

mkdir -p /mnt/hgfs/ocp/ocp4
rsync --info=progress2 -P --delete -arz --no-o --no-g --no-perms  /data/ocp4/  /mnt/hgfs/ocp/ocp4/

mkdir -p /mnt/hgfs/ocp/registry
rsync --info=progress2 -P --delete -arz --no-o --no-g --no-perms  /data/registry/  /mnt/hgfs/ocp/registry/

mkdir -p /mnt/hgfs/ocp/is.samples
rsync --info=progress2 -P --delete -arz --no-o --no-g --no-perms  /data/is.samples/  /mnt/hgfs/ocp/is.samples/



######################
## on kvm host
systemctl stop docker-distribution

cd /data

rm -rf registry
# tar zxf registry.tgz
yum -y install pigz

pigz -dc registry.tgz | tar xf -

systemctl restart docker-distribution


oc adm upgrade --to-image=registry.redhat.ren/ocp4/openshift4

```

osx
```bash
git config --global credential.helper store
```