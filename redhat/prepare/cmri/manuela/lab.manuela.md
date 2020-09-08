# cmri labs install for manuela

https://github.com/sa-mw-dach/manuela/blob/master/docs/BOOTSTRAP.md

## jumpbox

```bash

yum install icedtea-web

# to crmi
rsync -e ssh --info=progress2 -P --delete -arz  /root/data root@172.29.159.3:/home/wzh/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz  /data/ocp4/ root@172.29.159.3:/home/wzh/ocp4/

rsync -e ssh --info=progress2 -P --delete -arz  /data/registry/  root@172.29.159.3:/home/wzh/registry/

rsync -e ssh --info=progress2 -P --delete -arz  /data/is.samples/ root@172.29.159.3:/home/wzh/is.samples/

rsync -e ssh --info=progress2 -P --delete -arz  /data/mirror_dir/ root@172.29.159.3:/home/wzh/mirror_dir/

tar -cvf - is.samples/ | pigz -c > is.samples.tgz
tar -cvf - ocp4/ | pigz -c > ocp4.tgz
tar -cvf - registry/ | pigz -c > registry.tgz
tar -cvf - rhel-data/ | pigz -c > rhel-data.tgz


```

## try with ovs
https://pinrojas.com/2017/05/03/how-to-use-virt-install-to-connect-at-openvswitch-bridges/

https://blog.csdn.net/wuliangtianzu/article/details/81870551

https://stackoverflow.com/questions/30622680/kvm-ovs-bridged-network-how-to-configure

https://stackoverflow.com/questions/31566658/setup-private-networking-between-two-hosts-and-two-vms-with-libvirt-openvswitc

follow this to setup ovs network:
https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.4/4.4.ovs.md

## cluser-01

### redhat-01

```bash
# on redhat-01
timedatectl set-timezone Asia/Shanghai

pvcreate /dev/sdb
vgcreate datavg /dev/sdb

lvcreate -L 1T -n datalv datavg
mkfs.ext4 /dev/datavg/datalv
mount /dev/datavg/datalv /data

# rclone config
# rclone lsd jumpbox:
# rclone sync jumpbox:/home/wzh/  /data/down/ -P -L --transfers 10

rsync -e ssh --info=progress2 -P --delete -arz  root@172.29.159.3:/home/wzh/is.samples/  /data/down/is.samples/

rsync -e ssh --info=progress2 -P --delete -arz  root@172.29.159.3:/home/wzh/mirror_dir/  /data/down/mirror_dir/

pigz -dc registry.tgz | tar xf -
pigz -dc is.samples.tgz | tar xf -
pigz -dc rhel-data.tgz | tar xf -
pigz -dc ocp4.tgz | tar xf -

yum -y install vsftpd
systemctl enable --now vsftpd

mkdir -p /var/ftp/data
mount --bind /data/down/rhel-data/data /var/ftp/data
chcon -R -t public_content_t  /var/ftp/data

mkdir /etc/crts/ && cd /etc/crts
openssl req \
   -newkey rsa:2048 -nodes -keyout redhat.ren.key \
   -x509 -days 3650 -out redhat.ren.crt -subj \
   "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.redhat.ren"

cp /etc/crts/redhat.ren.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

yum -y install podman docker-distribution pigz skopeo
# pigz -dc registry.tgz | tar xf -
cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /data/down/registry
    delete:
        enabled: true
http:
    addr: :5443
    tls:
       certificate: /etc/crts/redhat.ren.crt
       key: /etc/crts/redhat.ren.key
EOF

systemctl enable --now docker-distribution
systemctl restart docker-distribution

mkdir -p /data/kvm
cd /data/kvm

lvremove -f datavg/helperlv
lvcreate -y -L 430G -n helperlv datavg

wipefs --all --force /dev/datavg/helperlv

# 430G
virt-install --name="ocp4-aHelper" --vcpus=2 --ram=4096 \
--disk path=/dev/datavg/helperlv,device=disk,bus=virtio,format=raw \
--os-variant centos7.0 --network network:br-int,model=virtio \
--boot menu=on --location /data/kvm/rhel-server-7.8-x86_64-dvd.iso \
--initrd-inject /data/kvm/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" 

scp /etc/crts/* 192.168.7.11:/root/
scp /data/down/ocp4.tgz 192.168.7.11:/root/
scp /data/down/ocp4-upi-helpernode.zip 192.168.7.11:/root/ocp4


```


### helper

```bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://192.168.7.1/data
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
# podman load -i fedora.tgz
podman load -i filetranspiler.tgz
# 根据现场环境，修改 ocp4-upi-helpernode-master/vars-static.yaml
cd ocp4-upi-helpernode

vi vars-static.yaml

ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml


# on helper node
cd /root/ocp4
mkdir -p /data
# export BUILDNUMBER=$(cat release.txt | grep 'Name:' | awk '{print $NF}')
export BUILDNUMBER=4.4.7
echo ${BUILDNUMBER}
# export BUILDNUMBER=4.2.4
export OCP_RELEASE=${BUILDNUMBER}
export LOCAL_REG='registry.redhat.ren:5443'
export LOCAL_REPO='ocp4/openshift4'
export UPSTREAM_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="/data/pull-secret.json"
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
export RELEASE_NAME="ocp-release"

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
EOF

cat << 'EOF' >> /etc/sysconfig/network-scripts/ifcfg-eth0
MTU=1450
EOF
systemctl restart network

cd /root/ocp4

vi install-config.yaml 

/bin/rm -rf *.ign .openshift_install_state.json auth bootstrap master0 master1 master2 worker0 worker1 worker2

# openshift-install create ignition-configs --dir=/root/ocp4
openshift-install create manifests --dir=/root/ocp4
# scp calico/manifests to manifests

# https://access.redhat.com/solutions/5092381
cat << 'EOF' > /root/ocp4/30-mtu.sh
#!/bin/sh
MTU=1450
INTERFACE=ens3

IFACE=$1
STATUS=$2
if [ "$IFACE" = "$INTERFACE" -a "$STATUS" = "up" ]; then
    ip link set "$IFACE" mtu $MTU
fi
EOF

cat /root/ocp4/30-mtu.sh | base64 -w0

cat << EOF > /root/ocp4/manifests/30-mtu.yaml
kind: MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
metadata:
  name: 99-worker-mtu
  creationTimestamp: 
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - filesystem: root
        path: "/etc/NetworkManager/dispatcher.d/30-mtu"
        contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL3NoCk1UVT05MDAwCklOVEVSRkFDRT1lbnM0CgpJRkFDRT0kMQpTVEFUVVM9JDIKaWYgWyAiJElGQUNFIiA9ICIkSU5URVJGQUNFIiAtYSAiJFNUQVRVUyIgPSAidXAiIF07IHRoZW4KICAgIGlwIGxpbmsgc2V0ICIkSUZBQ0UiIG10dSAkTVRVCmZpCg==
          verification: {}
        mode: 0755
    systemd:
      units:
        - contents: |
            [Unit]
            Requires=systemd-udevd.target
            After=systemd-udevd.target
            Before=NetworkManager.service
            DefaultDependencies=no
            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/restorecon /etc/NetworkManager/dispatcher.d/30-mtu
            [Install]
            WantedBy=multi-user.target
          name: one-shot-mtu.service
          enabled: true
EOF

cat << EOF > /root/ocp4/manifests/30-mtu.yaml
kind: MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
metadata:
  name: 99-worker-mtu
  creationTimestamp: 
  labels:
    machineconfiguration.openshift.io/role: master
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - filesystem: root
        path: "/etc/NetworkManager/dispatcher.d/30-mtu"
        contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL3NoCk1UVT05MDAwCklOVEVSRkFDRT1lbnM0CgpJRkFDRT0kMQpTVEFUVVM9JDIKaWYgWyAiJElGQUNFIiA9ICIkSU5URVJGQUNFIiAtYSAiJFNUQVRVUyIgPSAidXAiIF07IHRoZW4KICAgIGlwIGxpbmsgc2V0ICIkSUZBQ0UiIG10dSAkTVRVCmZpCg==
          verification: {}
        mode: 0755
    systemd:
      units:
        - contents: |
            [Unit]
            Requires=systemd-udevd.target
            After=systemd-udevd.target
            Before=NetworkManager.service
            DefaultDependencies=no
            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/restorecon /etc/NetworkManager/dispatcher.d/30-mtu
            [Install]
            WantedBy=multi-user.target
          name: one-shot-mtu.service
          enabled: true
EOF

openshift-install create ignition-configs --dir=/root/ocp4


/bin/cp -f bootstrap.ign /var/www/html/ignition/bootstrap-static.ign
/bin/cp -f master.ign /var/www/html/ignition/master-0.ign
/bin/cp -f master.ign /var/www/html/ignition/master-1.ign
/bin/cp -f master.ign /var/www/html/ignition/master-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-2.ign

chmod 644 /var/www/html/ignition/*

```

### redhat-01

```bash


yum -y install genisoimage libguestfs-tools
systemctl enable --now libvirtd

export NGINX_DIRECTORY=/data/ocp4
export RHCOSVERSION=4.4.3
export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.x86_64.iso | awk '/Volume id/ { print $3 }')
TEMPDIR=$(mktemp -d)
echo $VOLID
echo $TEMPDIR

cd ${TEMPDIR}
# Extract the ISO content using guestfish (to avoid sudo mount)
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.x86_64.iso \
  -m /dev/sda tar-out / - | tar xvf -

# Helper function to modify the config files
modify_cfg(){
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    # Append the proper image and ignition urls
    sed -e '/coreos.inst=yes/s|$| coreos.inst.install_dev=vda coreos.inst.image_url='"${URL}"'\/install\/'"${BIOSMODE}"'.raw.gz coreos.inst.ignition_url='"${URL}"'\/ignition\/'"${NODE}"'.ign ip='"${IP}"'::'"${GATEWAY}"':'"${NETMASK}"':'"${FQDN}"':'"${NET_INTERFACE}"':none:'"${MTU}"' nameserver='"${DNS}"'|' ${file} > $(pwd)/${NODE}_${file##*/}
    # Boot directly in the installation
    sed -i -e 's/default vesamenu.c32/default linux/g' -e 's/timeout 600/timeout 10/g' $(pwd)/${NODE}_${file##*/}
  done
}

URL="http://192.168.7.11:8080/"
GATEWAY="192.168.7.1"
NETMASK="255.255.255.0"
DNS="192.168.7.11"
MTU="1450"

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

export NGINX_DIRECTORY=/data/ocp4
cd ${NGINX_DIRECTORY}

# scp *.iso root@172.29.159.100:/data/ocp4/

create_lv() {
    var_name=$1
    lvremove -f datavg/$var_name
    lvcreate -y -L 120G -n $var_name datavg
    # wipefs --all --force /dev/datavg/$var_name
}

create_lv bootstraplv
create_lv master0lv
create_lv master1lv
create_lv master2lv
create_lv worker0lv
create_lv worker1lv

# finally, we can start install :)
# 你可以一口气把虚拟机都创建了，然后喝咖啡等着。
# 从这一步开始，到安装完毕，大概30分钟。
virt-install --name=ocp4-bootstrap --vcpus=4 --ram=8192 \
--disk path=/dev/datavg/bootstraplv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/bootstrap-static.iso   

# 想登录进coreos一探究竟？那么这么做
# ssh core@192.168.7.12 
# journalctl -b -f -u bootkube.service

virt-install --name=ocp4-master0 --vcpus=4 --ram=16384 \
--disk path=/dev/datavg/master0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-0.iso 

# ssh core@192.168.7.13

virt-install --name=ocp4-master1 --vcpus=4 --ram=16384 \
--disk path=/dev/datavg/master1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-1.iso 

virt-install --name=ocp4-master2 --vcpus=4 --ram=16384 \
--disk path=/dev/datavg/master2lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-2.iso 

virt-install --name=ocp4-worker0 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-0.iso 

virt-install --name=ocp4-worker1 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-1.iso 


for i in vnet0 vnet1 vnet2 vnet3 vnet4 vnet5; do
    ovs-vsctl set int $i mtu_request=1450
done 



yum -y install haproxy
# scp haproxy.cfg to /data/ocp4/haproxy。cfg
/bin/cp -f /data/ocp4/haproxy.cfg /etc/haproxy/haproxy.cfg
setsebool -P haproxy_connect_any 1
systemctl enable --now haproxy
systemctl restart haproxy

```


### helper

```bash

openshift-install wait-for bootstrap-complete --log-level debug

cd ~/ocp4
export KUBECONFIG=/root/ocp4/auth/kubeconfig
echo "export KUBECONFIG=/root/ocp4/auth/kubeconfig" >> ~/.bashrc
source ~/.bashrc
oc get nodes

yum -y install jq
oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc adm certificate approve

openshift-install wait-for install-complete
# INFO Waiting up to 30m0s for the cluster at https://api.cmri.redhat.ren:6443 to initialize...
# INFO Waiting up to 10m0s for the openshift-console route to be created...
# INFO Install complete!
# INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/root/ocp4/auth/kubeconfig'
# INFO Access the OpenShift web-console here: https://console-openshift-console.apps.cmri.redhat.ren
# INFO Login to the console with user: kubeadmin, password: XF8ny-Unfey-LgPuf-d3oDG

bash ocp4-upi-helpernode/files/nfs-provisioner-setup.sh

oc patch configs.imageregistry.operator.openshift.io cluster -p '{"spec":{"managementState": "Managed","storage":{"pvc":{"claim":""}}}}' --type=merge

oc get clusteroperator image-registry

oc get configs.imageregistry.operator.openshift.io cluster -o yaml

oc patch configs.samples.operator.openshift.io/cluster -p '{"spec":{"managementState": "Managed"}}' --type=merge

oc patch configs.samples.operator.openshift.io/cluster -p '{"spec":{"managementState": "Unmanaged"}}' --type=merge

oc get configs.samples.operator.openshift.io/cluster -o yaml

oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'


# 如果想看到redhat的operator，这样做
# 镜像源在 docker.io/wangzheng422/custom-registry-redhat
cat <<EOF > redhat-operator-catalog.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: Redhat Operator Catalog
  sourceType: grpc
  image: registry.redhat.ren:5443/docker.io/wangzheng422/operator-catalog:redhat-4.4-2020-06-08
  publisher: Red Hat
EOF
oc create -f redhat-operator-catalog.yaml

# 如果想看到certified的operator，这样做
# 镜像源在 docker.io/wangzheng422/custom-registry-certified
cat <<EOF > certified-operator-catalog.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: certified-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: Certified Operator Catalog
  sourceType: grpc
  image: registry.redhat.ren:5443/docker.io/wangzheng422/operator-catalog:certified-4.4-2020-06-08
  publisher: Certified
EOF
oc create -f certified-operator-catalog.yaml


# 如果想看到community的operator，这样做
# 镜像源在 docker.io/wangzheng422/custom-registry-community
cat <<EOF > community-operator-catalog.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: community-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: Community Operator Catalog
  sourceType: grpc
  image: registry.redhat.ren:5443/docker.io/wangzheng422/operator-catalog:community-4.4-2020-06-08
  publisher: Community
EOF
oc create -f community-operator-catalog.yaml


oc get pods -n openshift-marketplace
oc get catalogsource -n openshift-marketplace
oc get packagemanifest -n openshift-marketplace

find . -name "*-operator-catalog.yaml" -exec oc delete -f {} \;

oc get imagepruner.imageregistry.operator.openshift.io/cluster
oc patch imagepruner.imageregistry.operator.openshift.io/cluster -p '{"spec":{"suspend": false}}' --type=merge



cd /root/ocp4

# scp /etc/crts/redhat.ren.crt 192.168.7.11:/root/ocp4/
oc project openshift-config
oc create configmap ca.for.registry \
    --from-file=registry.redhat.ren=/root/redhat.ren.crt
# 如果你想删除这个config map，这么做
# oc delete configmap ca.for.registry
oc patch image.config.openshift.io/cluster -p '{"spec":{"additionalTrustedCA":{"name":"ca.for.registry"}}}'  --type=merge
# oc patch image.config.openshift.io/cluster -p '{"spec":{"registrySources":{"insecureRegistries":["registry.redhat.ren"]}}}'  --type=merge
oc get image.config.openshift.io/cluster -o yaml

oc apply -f ./99-worker-zzz-container-registries.yaml -n openshift-config
oc apply -f ./99-master-zzz-container-registries.yaml -n openshift-config

cd /root/ocp4
bash is.patch.sh



```

### redhat-01
image sync
```bash
# on vultr
export OCP_RELEASE=4.4.11
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz
sudo tar xzf /data/ocp4/openshift-client-linux-$OCP_RELEASE.tar.gz -C /usr/local/sbin/ oc kubectl


bash add.image.sh is.openshift.list

# on redhat-01
cd /data/ocp4
bash add.image.load.sh /data/down/is.samples/mirror_dir

bash add.image.load.sh /data/down/mirror_dir



cat << EOF >>  /etc/hosts
127.0.0.1 registry.redhat.ren
127.0.0.1 maxcdn.bootstrapcdn.com ajax.googleapis.com at.alicdn.com cdnjs.cloudflare.com code.jquery.com
EOF

export OCP_RELEASE=4.4.7

sudo tar xzf /data/ocp4/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz -C /usr/local/sbin/ oc kubectl

sudo tar xzf /data/ocp4/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz -C /usr/local/sbin/ openshift-install

which oc
which openshift-install

oc completion bash | sudo tee /etc/bash_completion.d/openshift > /dev/null


nmcli connection modify enp2s0f0 ipv4.dns 192.168.7.11
nmcli connection reload
nmcli connection up enp2s0f0


# disable firefox cert validation
# firefox --ignore-certificate-errors

yum install -y chromium

chromium-browser --no-sandbox --ignore-certificate-errors &> /dev/null &

scp -3 root@v.redhat.ren:/data/mirror_dir.tgz root@172.29.159.99:/data/down/

```

## cluster-02


### redhat-02

```bash
# on redhat-02

lvcreate -L 1T -n datalv datavg
mkfs.ext4 /dev/datavg/datalv
mount /dev/datavg/datalv /data

mkdir -p /data/kvm
cd /data/kvm

lvremove -f datavg/helperlv
lvcreate -y -L 430G -n helperlv datavg

# 230G
virt-install --name="ocp4-aHelper" --vcpus=2 --ram=4096 \
--disk path=/dev/datavg/helperlv,device=disk,bus=virtio,format=raw \
--os-variant centos7.0 --network network:br-int,model=virtio \
--boot menu=on --location /data/kvm/rhel-server-7.8-x86_64-dvd.iso \
--initrd-inject /data/kvm/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" 


scp root@172.29.159.99:/etc/crts/redhat.ren.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract


```

### helper

```bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://172.29.159.99/data
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
# podman load -i fedora.tgz
podman load -i filetranspiler.tgz
# 根据现场环境，修改 ocp4-upi-helpernode-master/vars-static.yaml
cd ocp4-upi-helpernode

vi vars-static.yaml

ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml


# on helper node
cd /root/ocp4
mkdir -p /data
# export BUILDNUMBER=$(cat release.txt | grep 'Name:' | awk '{print $NF}')
export BUILDNUMBER=4.4.7
echo ${BUILDNUMBER}
# export BUILDNUMBER=4.2.4
export OCP_RELEASE=${BUILDNUMBER}
export LOCAL_REG='registry.redhat.ren:5443'
export LOCAL_REPO='ocp4/openshift4'
export UPSTREAM_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="/data/pull-secret.json"
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
export RELEASE_NAME="ocp-release"

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
EOF

cat << 'EOF' >> /etc/sysconfig/network-scripts/ifcfg-eth0
MTU=1450
EOF
systemctl restart network

cd /root/ocp4

vi install-config.yaml 

/bin/rm -rf *.ign .openshift_install_state.json auth bootstrap master0 master1 master2 worker0 worker1 worker2

# openshift-install create ignition-configs --dir=/root/ocp4
openshift-install create manifests --dir=/root/ocp4
# scp calico/manifests to manifests

# https://access.redhat.com/solutions/5092381
cat << 'EOF' > /root/ocp4/30-mtu.sh
#!/bin/sh
MTU=1450
INTERFACE=ens3

IFACE=$1
STATUS=$2
if [ "$IFACE" = "$INTERFACE" -a "$STATUS" = "up" ]; then
    ip link set "$IFACE" mtu $MTU
fi
EOF

cat /root/ocp4/30-mtu.sh | base64 -w0

cat << EOF > /root/ocp4/manifests/30-mtu.yaml
kind: MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
metadata:
  name: 99-worker-mtu
  creationTimestamp: 
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - filesystem: root
        path: "/etc/NetworkManager/dispatcher.d/30-mtu"
        contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL3NoCk1UVT05MDAwCklOVEVSRkFDRT1lbnM0CgpJRkFDRT0kMQpTVEFUVVM9JDIKaWYgWyAiJElGQUNFIiA9ICIkSU5URVJGQUNFIiAtYSAiJFNUQVRVUyIgPSAidXAiIF07IHRoZW4KICAgIGlwIGxpbmsgc2V0ICIkSUZBQ0UiIG10dSAkTVRVCmZpCg==
          verification: {}
        mode: 0755
    systemd:
      units:
        - contents: |
            [Unit]
            Requires=systemd-udevd.target
            After=systemd-udevd.target
            Before=NetworkManager.service
            DefaultDependencies=no
            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/restorecon /etc/NetworkManager/dispatcher.d/30-mtu
            [Install]
            WantedBy=multi-user.target
          name: one-shot-mtu.service
          enabled: true
EOF

cat << EOF > /root/ocp4/manifests/30-mtu.yaml
kind: MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
metadata:
  name: 99-worker-mtu
  creationTimestamp: 
  labels:
    machineconfiguration.openshift.io/role: master
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - filesystem: root
        path: "/etc/NetworkManager/dispatcher.d/30-mtu"
        contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL3NoCk1UVT05MDAwCklOVEVSRkFDRT1lbnM0CgpJRkFDRT0kMQpTVEFUVVM9JDIKaWYgWyAiJElGQUNFIiA9ICIkSU5URVJGQUNFIiAtYSAiJFNUQVRVUyIgPSAidXAiIF07IHRoZW4KICAgIGlwIGxpbmsgc2V0ICIkSUZBQ0UiIG10dSAkTVRVCmZpCg==
          verification: {}
        mode: 0755
    systemd:
      units:
        - contents: |
            [Unit]
            Requires=systemd-udevd.target
            After=systemd-udevd.target
            Before=NetworkManager.service
            DefaultDependencies=no
            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/restorecon /etc/NetworkManager/dispatcher.d/30-mtu
            [Install]
            WantedBy=multi-user.target
          name: one-shot-mtu.service
          enabled: true
EOF

openshift-install create ignition-configs --dir=/root/ocp4


/bin/cp -f bootstrap.ign /var/www/html/ignition/bootstrap-static.ign
/bin/cp -f master.ign /var/www/html/ignition/master-0.ign
/bin/cp -f master.ign /var/www/html/ignition/master-1.ign
/bin/cp -f master.ign /var/www/html/ignition/master-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-2.ign

chmod 644 /var/www/html/ignition/*

```




### redhat-02

```bash

export NGINX_DIRECTORY=/data/ocp4
cd $NGINX_DIRECTORY

create_lv() {
    var_name=$1
    lvremove -f datavg/$var_name
    lvcreate -y -L 120G -n $var_name datavg
    # wipefs --all --force /dev/datavg/$var_name
}

create_lv bootstraplv
create_lv master0lv
create_lv master1lv
create_lv master2lv
create_lv worker0lv
create_lv worker1lv

# finally, we can start install :)
# 你可以一口气把虚拟机都创建了，然后喝咖啡等着。
# 从这一步开始，到安装完毕，大概30分钟。
virt-install --name=ocp4-bootstrap --vcpus=4 --ram=8192 \
--disk path=/dev/datavg/bootstraplv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/bootstrap-static.iso   

# 想登录进coreos一探究竟？那么这么做
# ssh core@192.168.7.12 
# journalctl -b -f -u bootkube.service

virt-install --name=ocp4-master0 --vcpus=4 --ram=16384 \
--disk path=/dev/datavg/master0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-0.iso 

# ssh core@192.168.7.13

virt-install --name=ocp4-master1 --vcpus=4 --ram=16384 \
--disk path=/dev/datavg/master1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-1.iso 

virt-install --name=ocp4-master2 --vcpus=4 --ram=16384 \
--disk path=/dev/datavg/master2lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-2.iso 

virt-install --name=ocp4-worker0 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker0lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-0.iso 

virt-install --name=ocp4-worker1 --vcpus=8 --ram=32768 \
--disk path=/dev/datavg/worker1lv,device=disk,bus=virtio,format=raw \
--os-variant rhel8.0 --network network:br-int,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-1.iso 


for i in vnet0 vnet1 vnet2 vnet3 vnet4 vnet5; do
    ovs-vsctl set int $i mtu_request=1450
done 



yum -y install haproxy
# scp haproxy.cfg to /data/ocp4/haproxy。cfg
/bin/cp -f /data/ocp4/haproxy.cfg /etc/haproxy/haproxy.cfg
setsebool -P haproxy_connect_any 1
systemctl enable --now haproxy
systemctl restart haproxy

```