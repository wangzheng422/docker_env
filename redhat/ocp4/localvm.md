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

yum install open-vm-tools
systemctl start vmware-tools

cd
tar -cvf - data/ | pigz -c > /mnt/hgfs/ocp.4.2.4/rhel-data.tgz

cd /data
tar -cvf - ocp4/ | pigz -c > /mnt/hgfs/ocp.4.2.4/ocp4.tgz
tar -cvf - registry/ | pigz -c > /mnt/hgfs/ocp.4.2.4/registry.tgz

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