# openshift 3.11.98 离线安装

based on <https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html> and <http://ksoong.org/docs/content/openshift/install/>

以下文章中的命令，不是安装时候的顺序执行命令，请搞懂命令的含义，按照自己的需要取用。

## 机器规划

```bash
cat << EOF >> /etc/hosts

192.168.39.135  yum yum.redhat.ren
192.168.39.31  kni-master kni-master.redhat.ren kni-registry kni-registry.redhat.ren kni-paas kni-paas.redhat.ren
192.168.39.154  kni-infra kni-infra.redhat.ren
192.168.39.32  kni-node1 kni-node1.redhat.ren
192.168.39.33  kni-node2 kni-node2.redhat.ren
192.168.39.34  kni-node3 kni-node3.redhat.ren
192.168.39.152  kni-node4 kni-node4.redhat.ren

# 192.168.39.154 *.kni-apps.redhat.ren

EOF
```

## rhel 安装源准备

```bash
ssh -i ~/.ssh/id_rsa.redhat -p 6001 -tt root@a1.wandering.wang byobu

```

## 准备docker镜像

在一台centos云主机上面（合适的地理位置），安装docker，然后运行 pull-images.sh，会自动下载镜像，并且打包。

写这个脚本，是因为发现官方的镜像，有一些版本标签不对，需要手动的调整，需要的话，修改 config.sh

下载的镜像，总共12G左右

## 主机IP地址

```bash

timedatectl set-timezone Asia/Shanghai

hostnamectl set-hostname kni-master.redhat.ren
nmcli connection modify enp1s0f0 ipv4.addresses 192.168.39.31/24
nmcli connection modify enp1s0f0 ipv4.gateway 192.168.39.254
nmcli connection modify enp1s0f0 ipv4.dns 192.168.39.31
nmcli connection modify enp1s0f0 ipv4.method manual
nmcli connection modify enp1s0f0 connection.autoconnect yes
nmcli connection reload
nmcli connection up enp1s0f0

hostnamectl set-hostname kni-infra.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.154/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.31
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

hostnamectl set-hostname kni-node1.redhat.ren
nmcli connection modify enp1s0f0 ipv4.addresses 192.168.39.32/24
nmcli connection modify enp1s0f0 ipv4.gateway 192.168.39.254
nmcli connection modify enp1s0f0 ipv4.dns 192.168.39.31
nmcli connection modify enp1s0f0 ipv4.method manual
nmcli connection modify enp1s0f0 connection.autoconnect yes
nmcli connection reload
nmcli connection up enp1s0f0

hostnamectl set-hostname kni-node2.redhat.ren
nmcli connection modify enp1s0f0 ipv4.addresses 192.168.39.33/24
nmcli connection modify enp1s0f0 ipv4.gateway 192.168.39.254
nmcli connection modify enp1s0f0 ipv4.dns 192.168.39.31
nmcli connection modify enp1s0f0 ipv4.method manual
nmcli connection modify enp1s0f0 connection.autoconnect yes
nmcli connection reload
nmcli connection up enp1s0f0

hostnamectl set-hostname kni-node3.redhat.ren
nmcli connection modify enp1s0f0 ipv4.addresses 192.168.39.34/24
nmcli connection modify enp1s0f0 ipv4.gateway 192.168.39.254
nmcli connection modify enp1s0f0 ipv4.dns 192.168.39.31
nmcli connection modify enp1s0f0 ipv4.method manual
nmcli connection modify enp1s0f0 connection.autoconnect yes
nmcli connection reload
nmcli connection up enp1s0f0

hostnamectl set-hostname kni-node4.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.152/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.31
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

lshw -class network

lspci | egrep -i --color 'network|ethernet'

```

## ntp 时间源

服务器配置和客户端不一样，服务器需要把本地时钟作为源。

```bash
vi /etc/chrony.conf
systemctl restart chronyd
systemctl status chronyd
chronyc tracking
chronyc sources -v
chronyc sourcestats -v
chronyc makestep

firewall-cmd --permanent --add-port=123/udp
firewall-cmd --reload

firewall-cmd --list-all

timedatectl set-ntp true
```

## 配置yum源

我们用vsftpd来做yum源。先把之前弄好的yum镜像，解压缩到本地。

```bash
mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://yum.redhat.ren/data
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist
yum -y install byobu htop

# 一些基础的包
# yum -y update
# yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion vim lrzsz unzip htop

```

## registry安装

证书处理，如何你有域名，那么参照一下文章，搞一个泛域名证书就好了。

<https://www.hi-linux.com/posts/6968.html>

不过文章里面需要下载命令行工具，我们可以用docker来做这件事情

```bash
cd /Users/wzh/Documents/redhat/tools/redhat.ren
docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/redhat.ren/fullchain1.pem redhat.ren.fullchain1.pem
cp ./etc/archive/redhat.ren/privkey1.pem redhat.ren.privkey1.pem

docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/kni-apps.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/kni-apps.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.kni-apps.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/kni-apps.redhat.ren/fullchain1.pem kni-apps.redhat.ren.fullchain1.pem
cp ./etc/archive/kni-apps.redhat.ren/privkey1.pem kni-apps.redhat.ren.privkey1.pem
cp ./etc/archive/kni-apps.redhat.ren/chain1.pem kni-apps.redhat.ren.chain1.pem

```

有了证书，就让我们愉快的开始registry安装吧。

```bash

# yum上面装
yum -y install docker-distribution

# 把 Let’s Encrypt 上传到服务器上面
mkdir /etc/crts/
cp redhat.ren.crt /etc/crts/redhat.ren.crt
cp redhat.ren.key /etc/crts/redhat.ren.key


mkdir -p /data/registry
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
http:
    addr: :5021
    tls:
       certificate: /etc/crts/redhat.ren.crt
       key: /etc/crts/redhat.ren.key
EOF

systemctl daemon-reload
systemctl restart docker-distribution
systemctl enable docker-distribution

# 打开防火墙
firewall-cmd --get-active-zones
firewall-cmd --zone=public --add-port=5021/tcp --permanent
firewall-cmd --reload

firewall-cmd --list-all

# 把之前下载的镜像导入本地
# docker load -i ose3-images.tgz
# docker load -i ose3-optional-imags.tgz
# docker load -i ose3-builder-images.tgz
# docker load -i docker-builder-images.tgz
# docker load -i other-builder-images.tgz

```

运行 load-images.sh 来向镜像仓库倒入镜像

## cri-o

```bash
yum install cri-o crictl podman buildah skopeo pigz

yum remove cri-o crictl podman buildah skopeo pigz

systemctl enable cri-o
systemctl start cri-o

yum install docker
systemctl start docker
systemctl enable docker 
```

## 准备DNS

```bash

yum -y install dnsmasq

cat  > /etc/dnsmasq.d/openshift-cluster.conf << EOF
local=/redhat.ren/
address=/.kni-apps.redhat.ren/192.168.39.154
address=/kni-master.redhat.ren/192.168.39.31
address=/kni-infra.redhat.ren/192.168.39.154
address=/kni-node1.redhat.ren/192.168.39.32
address=/kni-node2.redhat.ren/192.168.39.33
address=/kni-node3.redhat.ren/192.168.39.34
address=/kni-node4.redhat.ren/192.168.39.152
address=/kni-registry.redhat.ren/192.168.39.31
address=/kni-paas.redhat.ren/192.168.39.31
EOF

# master节点，本次环境没有外网，也没有上级dns，就不用做这里了。
cat > /etc/dnsmasq.d/origin-upstream-dns.conf << EOF 
server=192.168.253.2
EOF



systemctl start dnsmasq.service && systemctl enable dnsmasq.service && systemctl status dnsmasq.service

firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

systemctl restart dnsmasq

```

## 准备安装

3.11的文档说，nfs已经不推荐了，让用glusterfs

```bash
# 3.11的文档说，nfs已经不推荐了，让用glusterfs
#yum -y install openshift-ansible nfs-utils rpcbind
#systemctl enable nfs-server

# firewall-cmd --permanent --add-service=nfs
# firewall-cmd --permanent --add-service=mountd
# firewall-cmd --permanent --add-service=rpc-bind
# firewall-cmd --reload

# yum info <package name>
# yum list <package name>
# yum --showduplicates list <package name>
yum --showduplicates list ansible
yum downgrade ansible-2.6.16-1.el7ae
yum install ansible-2.6.16-1.el7ae openshift-ansible

yum list $(yum search -q openshift | awk '{print $1}' | grep -v : | head -n -2)

# 清理文件系统
# https://www.cyberciti.biz/faq/howto-use-wipefs-to-wipe-a-signature-from-disk-on-linux/
wipefs --all --force /dev/sda1

# dhcp 检测命令
nmap --script broadcast-dhcp-discover

```

nfs 相关操作 <https://linuxconfig.org/quick-nfs-server-configuration-on-redhat-7-linux>

sr-iov 参考项目 <https://github.com/openshift/ose-sriov-network-device-plugin>，这里面，sriov-network-device-plugin 编译镜像这个，似乎可以不用做，因为docker.io 上面有。

kubevirt 参考文章 <https://blog.openshift.com/getting-started-with-kubevirt/>， 这里面有一个隐藏的，关于制作虚拟机镜像的文章，在这里<https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/disks-and-volumes.html>，找到 containerDisk 的章节，这个意思就是虚拟机镜像，就放到registry里面就可以了，但是这个镜像，要特殊的来做。

GPU 参考 <https://blog.openshift.com/how-to-use-gpus-with-deviceplugin-in-openshift-3-10/>

## ssh 免密登录

```bash
for i in kni-master kni-infra kni-node1 kni-node2 kni-node3 kni-node4; do ssh-copy-id $i.redhat.ren; done;

for i in kni-master kni-infra kni-node1 kni-node2 kni-node3 kni-node4; do ssh $i.redhat.ren 'date'; done

```

## ansible-console

以下内容，不能全部执行，根据需要自取。

```bash
ansible-console cmcc -u root

# 以下不要在ntp server上运行
copy src=./chrony_other.conf dest=/etc/chrony.conf
systemd name=chronyd state=restarted enabled=no

# copy src=./hosts dest=/etc/hosts

# yum_repository name=ftp description=ftp baseurl=ftp://yum.redhat.ren/data gpgcheck=no state=present

# yum name=byobu

# timezone name=Asia/Shanghai

# file path=/data/docker state=directory
# file src=/data/docker dest=/var/lib/docker state=link

yum name=nc,net-tools,ansible-2.6.16-1.el7ae,iptables-services,ncdu,lftp,byobu,glances,htop,lsof,ntpdate,bash-completion,wget,nmon,vim,httpd-tools,unzip,git,bind-utils,bridge-utils,lrzsz,openshift-ansible,glusterfs-fuse,kubevirt-virtctl,kubevirt-ansible

yum name=docker state=absent

# epel的ansible版本是2.7， openshift必须用2.6的。
# yum name=ansible state=absent
# yum name=ansible-2.6.13-1.el7ae,openshift-ansible

# systemd name=docker state=stopped enabled=no

# file path=/data/docker state=absent
# file path=/data/docker state=directory

# rhel下面，改docker的数据目录，由于selinux的限制，不能做软连接。
# copy src=./sysconfig/docker dest=/etc/sysconfig/docker

# systemd name=docker state=started enabled=yes

# lineinfile path=/etc/sysconfig/docker regexp="^INSECURE_REGISTRY" state=absent

lineinfile path=/etc/ssh/sshd_config regexp="^UseDNS" line="UseDNS no" insertafter=EOF state=present
systemd name=sshd state=restarted enabled=yes

shell crictl stopp $(crictl pods -q)
shell crictl rmp $(crictl pods -q)

shell vgremove -f $(vgs | tail -1 | awk '{print $1}')
shell pvremove $(pvs | tail -1 | awk '{print $1}')

# shell semanage fcontext -a -t container_var_lib_t "/data/docker(/.*)?"
# shell semanage fcontext -a -t container_share_t "/data/docker/overlay2(/.*)?"
# shell restorecon -r /data/docker

# systemd name=docker state=stopped enabled=no
# file path=/var/lib/docker state=absent
# file path=/var/lib/docker state=directory
```

## 加载镜像

```bash
docker load -i ose3-images.tgz
docker load -i ose3-optional-imags.tgz
docker load -i ose3-builder-images.tgz
docker load -i docker-builder-images.tgz
docker load -i other-builder-images.tgz

# admin/Harbor12345
bash load-images.sh

```

## 开始安装

在安装的时候，发现需要手动的push openshift3/ose:latest这个镜像，随便什么内容都可以。不然检查不过。我用的openshift3/ose-node 这个镜像。

```bash
ansible-playbook -v -i hosts-3.11.98.cnv.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -v -i hosts-3.11.98.cnv.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -v -i hosts-3.11.98.cnv.yaml /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml

ansible-playbook -v -i hosts-3.11.98.cnv.yaml /usr/share/ansible/openshift-ansible/playbooks/openshift-metrics/config.yml

# if uninstall, on each glusterfs nodes, run
vgremove -f $(vgs | tail -1 | awk '{print $1}')
pvremove $(pvs | tail -1 | awk '{print $1}')
# pvremove /dev/sdb2

crictl stopp $(crictl pods -q)
crictl rmp $(crictl pods -q)

htpasswd -cb /etc/origin/master/htpasswd admin  admin

oc adm policy add-cluster-role-to-user cluster-admin admin
oc adm policy remove-cluster-role-from-user cluster-admin admin
```
## kni

```bash
oc login -u system:admin
cd /usr/share/ansible/kubevirt-ansible
ansible-playbook -v -i /data/down/ocp/hosts-3.11.98.cnv.yaml -e @vars/cnv.yml playbooks/kubevirt.yml \
-e apb_action=provision -e registry_url=kni-registry.redhat.ren:5021 -e docker_tag=latest

ansible-playbook -v -i /data/down/ocp/hosts-3.11.98.cnv.yaml -e @vars/cnv.yml playbooks/kubevirt.yml \
-e apb_action=deprovision -e registry_url=kni-registry.redhat.ren:5021 -e docker_tag=latest

oc delete route -n cdi cdi-uploadproxy-route

oc get secret -n cdi cdi-upload-proxy-ca-key -o=jsonpath="{.data['tls\.crt']}" | base64 -d > ca.pem

oc create route reencrypt cdi-uploadproxy-route -n cdi --service=cdi-uploadproxy --dest-ca-cert=ca.pem


```

以下命令是做实验的时候，走的弯路，打算装一个kvm，启动虚拟机，安装win7，把镜像弄到手，然后导入kni集群，直接启动这个镜像。

实际发现，这个镜像启动不了，似乎是kni的硬件配置和kvm里面的差别非常大，只能去kni里面直接来安装一个新的操作系统。

```bash

yum install qemu-img kvm

# qemu-img convert -f raw -O qcow2 cn_windows_7_ultimate_with_sp1_x64_dvd_618537.iso win7_iso.qcow2

# cp cn_windows_7_ultimate_with_sp1_x64_dvd_618537.iso win7_iso.raw

virtctl image-upload --uploadproxy-url=https://$(oc get route cdi-uploadproxy-route -n cdi -o=jsonpath='{.status.ingress[0].host}') --pvc-name=upload-win7-pvc --pvc-size=11Gi --image-path=/data/down/virtio-win/win7.qcow2 --insecure

virtctl image-upload --uploadproxy-url=https://$(oc get route cdi-uploadproxy-route -n cdi -o=jsonpath='{.status.ingress[0].host}') --pvc-name=upload-win7-install-pvc --pvc-size=4Gi --image-path=/data/down/virtio-win/cn_windows_7_ultimate_with_sp1_x64_dvd_618537.iso --insecure

cd /var/lib/libvirt/images

# qemu-img create -f qcow2 win7sp1_x64.qcow2 50G

# kvm -m 4096 -cdrom cn_windows_7_ultimate_with_sp1_x64_dvd_618537.iso -drive file=win7sp1_x64.qcow2,if=virtio,boot=on -fda virtio-win-0.1.141_amd64.vfd -boot d -nographic -vnc :3

yum install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install virt-viewer

systemctl enable libvirtd
systemctl start libvirtd

firewall-cmd --zone=public --permanent --list-ports

# https://access.redhat.com/articles/2470791
# https://www.cyberciti.biz/faq/how-to-install-kvm-on-centos-7-rhel-7-headless-server/
# https://serverfault.com/questions/631317/windows-7-as-kvm-guest-installation-with-virtio-drivers-detected-virtio-scsi-d

virt-install \
--virt-type=kvm \
--name win7 \
--ram 4096 \
--vcpus=2 \
--os-variant=win7 \
--disk path=./virtio-win-0.1.141_amd64.vfd,device=floppy \
--cdrom=./cn_windows_7_ultimate_with_sp1_x64_dvd_618537.iso \
--network=network=default,model=virtio \
--graphics vnc,port=5900 \
--disk path=./win7.qcow2,size=10,bus=virtio,format=qcow2 \
--boot hd,cdrom,menu=on

virt-install \
--name win7 \
--ram 4096 \
--vcpus=2 \
--os-variant=win10 \
--disk path=./virtio-win-0.1.141_amd64.vfd,device=floppy \
--cdrom=./cn_windows_7_ultimate_with_sp1_x64_dvd_618537.iso \
--network=network=default,model=virtio \
--graphics vnc,port=5900 \
--disk path=./win7_10.qcow2,size=10,bus=virtio,format=qcow2 \
--boot hd,cdrom,menu=on

docker build -t win7_10boot ./
docker tag win7_10boot kni-registry.redhat.ren:5021/win7_10boot

docker build -t win7_install ./
docker tag win7_install kni-registry.redhat.ren:5021/win7_install

docker build -t win7_virtio_rhel ./
docker tag win7_virtio_rhel kni-registry.redhat.ren:5021/win7_virtio_rhel
docker push kni-registry.redhat.ren:5021/win7_virtio_rhel


virtctl expose virtualmachine win7 --name win7-rdp --port 3389 --target-port 3389 --type NodePort

# qemu-img convert -f qcow2  -O raw ./win7.qcow2 ./win7.raw
# gzip win7.raw

# virsh attach-disk win7 ./virtio-win-0.1.141.iso hdc --type cdrom --mode readonly 

virsh shutdown win7
virsh destroy win7
virsh undefine win7
virsh pool-destroy virtio-win
virsh list


python -m SimpleHTTPServer
python -m  http.server 8000
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload
```
