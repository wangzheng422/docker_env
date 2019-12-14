```bash

# on base host
cd /data
virt-install --name="ocp4-aHelper" --vcpus=2 --ram=4096 \
--disk path=/data/kvm/ocp4-aHelper.qcow2,bus=virtio,size=230 \
--os-variant centos7.0 --network network=openshift4,model=virtio \
--boot menu=on --location /data/rhel-server-7.6-x86_64-dvd.iso \
--initrd-inject helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" 

virt-viewer --domain-name ocp4-aHelper
virsh start ocp4-aHelper
virsh list --all

# in helper node
# ssh root@192.168.7.11
cat << EOF >>  /etc/hosts
192.168.7.1 yum.redhat.ren
EOF

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.redhat.ren/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist

yum -y install ansible git unzip podman
# scp ocp4.tgz to /root
cd /root
tar zvxf ocp4.tgz
cd /root/ocp4
unzip ocp4-upi-helpernode-master.zip
podman load -i fedora.tgz
# 根据现场环境，修改 ocp4-upi-helpernode-master/vars-static.yaml
cd ocp4-upi-helpernode-master
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml

# on helper node
cd /root/ocp4
export BUILDNUMBER=$(cat release.txt | grep 'Name:' | awk '{print $NF}')
echo ${BUILDNUMBER}
# export BUILDNUMBER=4.2.4
export OCP_RELEASE=${BUILDNUMBER}
export LOCAL_REG='registry.redhat.ren'
export LOCAL_REPO='ocp4/openshift4'
export UPSTREAM_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="pull-secret.json"
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
export RELEASE_NAME="ocp-release"

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
EOF

cd /root/ocp4
# scp ocp4.tgz to /root
# scp install-config.yaml to /root/ocp4
# 根据现场环境，修改 install-config.yaml
# 至少要修改ssh key， 还有 additionalTrustBundle，这个是镜像仓库的csr 
# example file at files/4.2/kvm/

# cp /root/ocp4/redhat.ren.crt /etc/pki/ca-trust/source/anchors/
# update-ca-trust extract

/bin/rm -rf *.ign metadata.json .openshift_install_state.json auth bootstrap master0 master1 master2 worker0 worker1 worker2

# 此处注意语言环境，最近发现中文环境会造成命令失败。
openshift-install create ignition-configs --dir=/root/ocp4

/bin/cp -f bootstrap.ign /var/www/html/ignition/bootstrap-static.ign
/bin/cp -f master.ign /var/www/html/ignition/master-0.ign
/bin/cp -f master.ign /var/www/html/ignition/master-1.ign
/bin/cp -f master.ign /var/www/html/ignition/master-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-2.ign

# go back to kvm host
cd /data/ocp4 

export NGINX_DIRECTORY=/data/ocp4
export RHCOSVERSION=4.2.0
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

URL="http://192.168.7.11:8080/"
GATEWAY="192.168.7.1"
NETMASK="255.255.255.0"
DNS="192.168.7.11"

# BOOTSTRAP
# TYPE="bootstrap"
NODE="bootstrap-static"
IP="192.168.7.12"
FQDN="bootstrap"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTERS
# TYPE="master"
# MASTER-0
NODE="master-0"
IP="192.168.7.13"
FQDN="master-0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-1
NODE="master-1"
IP="192.168.7.14"
FQDN="master-1"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-2
NODE="master-2"
IP="192.168.7.15"
FQDN="master-2"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# WORKERS
NODE="worker-0"
IP="192.168.7.16"
FQDN="worker-0"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-1"
IP="192.168.7.17"
FQDN="worker-1"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-2"
IP="192.168.7.18"
FQDN="worker-2"
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
cd
rm -Rf ${TEMPDIR}

cd /data/ocp4


# finally, we can start install :)
# 你可以一口气把虚拟机都创建了，然后喝咖啡等着。
# 从这一步开始，到安装完毕，大概30分钟。
virt-install --name=ocp4-bootstrap --vcpus=4 --ram=8192 \
--disk path=/data/kvm/ocp4-bootstrap.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/bootstrap-static.iso   

# 想登录进coreos一探究竟？那么这么做
# ssh core@192.168.7.12 
# journalctl -b -f -u bootkube.service

virt-install --name=ocp4-master0 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-master0.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/master-0.iso 

# ssh core@192.168.7.13

virt-install --name=ocp4-master1 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-master1.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/master-1.iso 

virt-install --name=ocp4-master2 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-master2.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/master-2.iso 

virt-install --name=ocp4-worker0 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-worker0.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/worker-0.iso 

virt-install --name=ocp4-worker1 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-worker1.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/worker-1.iso 

virt-install --name=ocp4-worker2 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/ocp4-worker2.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4,model=virtio \
--boot menu=on --cdrom /data/ocp4/worker-2.iso 

# on helper node
openshift-install wait-for bootstrap-complete --log-level debug

cd ~/ocp4
export KUBECONFIG=/root/ocp4/auth/kubeconfig
echo "export KUBECONFIG=/root/ocp4/auth/kubeconfig" >> ~/.bashrc
oc get nodes

bash ocp4-upi-helpernode-master/files/nfs-provisioner-setup.sh
oc patch configs.imageregistry.operator.openshift.io cluster -p '{"spec":{"storage":{"pvc":{"claim":""}}}}' --type=merge
oc get clusteroperator image-registry

openshift-install wait-for install-complete
# INFO Install complete!
# INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/root/ocp4/auth/kubeconfig'
# INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp4.redhat.ren
# INFO Login to the console with user: kubeadmin, password: kWT4A-mqe2h-gPUIx-vexAJ

```