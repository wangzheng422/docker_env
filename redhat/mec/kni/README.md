# openshift 3.11.81 离线安装

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

cp ./etc/archive/redhat.ren/fullchain1.pem redhat.ren.crt
cp ./etc/archive/redhat.ren/privkey1.pem redhat.ren.key

docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/kni-apps.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/kni-apps.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.kni-apps.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/kni-apps.redhat.ren/fullchain1.pem kni-apps.redhat.ren.crt
cp ./etc/archive/kni-apps.redhat.ren/privkey1.pem kni-apps.redhat.ren.key
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

## kubevirt

```bash
yum install -y virt-install virt-top

# with ansible
yum name=virt-install,virt-top
shell virt-host-validate qemu

# 以下权限命令，还要在新建的project里面使用。
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-privileged
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-controller
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-apiserver

oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-controller

cd kubevirt.0.14.0
oc apply -f kubevirt.yaml
oc delete -f kubevirt.yaml

oc new-project kubevirt-web-ui
cd deploy

oc apply -f service_account.yaml
oc adm policy add-scc-to-user anyuid -z kubevirt-web-ui-operator  # use the "anyuid" string as it is


oc apply -f role.yaml
oc apply -f role_extra_for_console.yaml
oc apply -f role_binding.yaml
oc apply -f role_binding_extra_for_console.yaml

oc apply -f crds/kubevirt_v1alpha1_kwebui_crd.yaml
oc apply -f crds/kubevirt_v1alpha1_kwebui_cr.yaml
oc apply -f operator.yaml
```

访问 <https://kubevirt-web-ui.apps.redhat.ren> , 就可以看到 kubevirt web ui了。

使用 vm/Dockerfile 制作虚拟机要用的镜像

```bash
docker build -t registry.redhat.ren/vmidisks/rhel7.6:latest .
docker push registry.redhat.ren/vmidisks/rhel7.6:latest

oc create configmap kubevirt-config --from-literal feature-gates=DataVolumes -n kube-system

oc create configmap kubevirt-config --from-literal feature-gates=DataVolumes -n test-wzh

oc apply -f vm.yaml

oc adm policy add-scc-to-user privileged -z default test-wzh

# 如果你想修改以下kvm镜像里面的内容
systemctl start libvirtd
export LIBGUESTFS_BACKEND=direct
guestmount -a ./rhel-server-7.6-x86_64-kvm.qcow2 -i  disk/
guestunmount disk/

# 用以下命令，作为启动脚本，这样就可以登录了。
cat /etc/passwd || cat /etc/shadow || useradd -p $( openssl passwd -1 wzhwzh ) wzh -s /bin/bash -G wheel || cat /etc/shadow

# 上面的方法好像不行，用下面的命令，base64编码
cat startup.sh | base64
```

然后在vm启动的yaml文件里面，用base64注入的方法，注入这个启动脚本。

```yaml
      volumes:
        - containerDisk:
            image: 'registry.redhat.ren/vmidisks/rhel7.6:latest'
          name: rootdisk
        - cloudInitNoCloud:
            userDataBase64: >-
              IyEvYmluL2Jhc2gKc2V0IC14CmNhdCAvZXRjL3Bhc3N3ZApjYXQgL2V0Yy9zaGFkb3cKdXNlcmFkZCAtcCAkKCBvcGVuc3NsIHBhc3N3ZCAtMSB3emh3emggKSB3emggLXMgL2Jpbi9iYXNoIC1HIHdoZWVsCmNhdCAvZXRjL3NoYWRvdw==
          name: cloudinitdisk
```

如果需要添加硬盘，需要装另外一个插件 <https://github.com/kubevirt/containerized-data-importer>，本次实验时间有限，而且实际场景下面，也许不太用到，等弄完sr-iov再回来做这个组件。

## sigma 服务支持

sigma需要docker的socker支持，需要添加如下docker启动参数，-H tcp://0.0.0.0:5678 -H unix:///var/run/docker.sock ， 就加到 /etc/sysconfig/docker里面， 另外别忘记把ansible 的 inventory 文件给改掉。