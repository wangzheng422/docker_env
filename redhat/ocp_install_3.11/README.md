# openshift 3.11.69 离线安装

based on 

<https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html>

<http://ksoong.org/docs/content/openshift/install/>

## 机器规划

```host
192.168.39.135  yum yum.redhat.ren
192.168.39.129  master master.redhat.ren registry registry.redhat.ren paas paas.redhat.ren
192.168.39.130  infra infra.redhat.ren
192.168.39.131  node1 node1.redhat.ren
192.168.39.132  node2 node2.redhat.ren
192.168.39.134  node4 node4.redhat.ren

192.168.39.130 *.apps.redhat.ren
```

## rhel 安装源准备

首先要做的，就是安装rhel操作系统了。去官网下周binary dvd, 4.2G左右。最小化安装就可以。

然后弄一下订阅的问题，这个在一台机器上弄就好了，我们之后把安装包导出来，去其他机器上面装。

```bash
subscription-manager register --username **** --password ********

subscription-manager list --available --all

subscription-manager attach --pool=********

subscription-manager repos --disable="*"

subscription-manager list --available --matches '*OpenShift Container Platform*'

subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms"

yum -y install wget yum-utils createrepo docker git

```

把epel的源也装上

```bash
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum install ./epel-release-latest-7.noarch.rpm

yum -y install htop byobu
```

GPU相关的包的源也装上

```bash
yum install -y https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.2.88-1.x86_64.rpm

curl -so /etc/yum.repos.d/nvidia-container-runtime.repo https://nvidia.github.io/nvidia-container-runtime/centos7/nvidia-container-runtime.repo
```

开始制作镜像安装源吧

```bash
reposync -n -d -l -m

# 如果想用group install，那么要这么下载
reposync --gpgcheck -n -d -l -m --downloadcomps --download-metadata
reposync -n -d -l -m --downloadcomps --download-metadata

createrepo ./
createrepo -g ./rhel-7-server-rpms/comps.xml --update .
```

镜像应该有30多G。

## 准备docker镜像

在一台centos云主机上面（合适的地理位置），安装docker，然后运行 pull-images.sh，会自动下载镜像，并且打包。

写这个脚本，是因为发现官方的镜像，有一些版本标签不对，需要手动的调整，需要的话，修改 config.sh

下载的镜像，总共12G左右

## 主机IP地址

```bash

timedatectl set-timezone Asia/Shanghai

hostnamectl set-hostname master.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.129/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.129
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

hostnamectl set-hostname infra.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.130/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.129
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

hostnamectl set-hostname node1.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.131/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.129
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

hostnamectl set-hostname node2.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.132/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.129
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

hostnamectl set-hostname node4.redhat.ren
nmcli connection modify eno2 ipv4.addresses 192.168.39.134/24
nmcli connection modify eno2 ipv4.gateway 192.168.39.254
nmcli connection modify eno2 ipv4.dns 192.168.39.129
nmcli connection modify eno2 ipv4.method manual
nmcli connection modify eno2 connection.autoconnect yes
nmcli connection reload
nmcli connection up eno2

lshw -class network

lspci | egrep -i --color 'network|ethernet'

```

## 配置yum源

我们用vsftpd来做yum源。先把之前弄好的yum镜像，解压缩到本地。

```bash
systemctl status chronyd
chronyc status

find . -name vsftp*
yum -y install ./data/rhel-7-server-rpms/Packages/vsftpd-3.0.2-25.el7.x86_64.rpm
mv /root/down/data /var/ftp/
systemctl start vsftpd
systemctl enable vsftpd

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

# 如果有问题，按照下面的链接，解决权限问题
# https://www.tuxfixer.com/vsftpd-installation-on-centos-7-with-selinux/
chown -R ftp:ftp /var/ftp
semanage fcontext -a -t public_content_rw_t /var/ftp
restorecon -Rvv /var/ftp
setsebool -P ftp_home_dir 1
setsebool -P ftpd_full_access 1
ls -lZ /var | grep ftp

firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload

# 一些基础的包
yum -y update
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion vim lrzsz unzip docker htop

```

## registry安装

证书处理，如何你有域名，那么参照一下文章，搞一个泛域名证书就好了。

<https://www.hi-linux.com/posts/6968.html>

不过文章里面需要下载命令行工具，我们可以用docker来做这件事情

```bash
docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/redhat.ren/fullchain1.pem redhat.ren.crt
cp ./etc/archive/redhat.ren/privkey1.pem redhat.ren.key

docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/apps.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/apps.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.apps.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/apps.redhat.ren/fullchain1.pem apps.redhat.ren.crt
cp ./etc/archive/apps.redhat.ren/privkey1.pem apps.redhat.ren.key
```

有了证书，就让我们愉快的开始registry安装吧。

```bash

# yum上面装
yum -y install docker-distribution

# 把 Let’s Encrypt 上传到服务器上面
mkdir /etc/crts/
cp fullchain1.pem /etc/crts/redhat.ren.crt
cp privkey1.pem /etc/crts/redhat.ren.key

cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /var/lib/registry
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
docker load -i ose3-images.tgz
docker load -i ose3-optional-imags.tgz
docker load -i ose3-builder-images.tgz
docker load -i docker-builder-images.tgz
docker load -i other-builder-images.tgz

```

运行 load-images.sh 来向镜像仓库倒入镜像

## 准备DNS

```bash

yum -y install dnsmasq

cat  > /etc/dnsmasq.d/openshift-cluster.conf << EOF
local=/redhat.ren/
address=/.apps.redhat.ren/192.168.39.130
address=/master.redhat.ren/192.168.39.129
address=/infra.redhat.ren/192.168.39.130
address=/node1.redhat.ren/192.168.39.131
address=/node2.redhat.ren/192.168.39.132
address=/node4.redhat.ren/192.168.39.134
address=/registry.redhat.ren/192.168.39.129
address=/paas.redhat.ren/192.168.39.129
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

yum -y install openshift-ansible

# dhcp 检测命令
nmap --script broadcast-dhcp-discover

```

nfs 相关操作 <https://linuxconfig.org/quick-nfs-server-configuration-on-redhat-7-linux>

sr-iov 参考项目 <https://github.com/openshift/ose-sriov-network-device-plugin>，这里面，sriov-network-device-plugin 编译镜像这个，似乎可以不用做，因为docker.io 上面有。

kubevirt 参考文章 <https://blog.openshift.com/getting-started-with-kubevirt/>， 这里面有一个隐藏的，关于制作虚拟机镜像的文章，在这里<https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/disks-and-volumes.html>，找到 containerDisk 的章节，这个意思就是虚拟机镜像，就放到registry里面就可以了，但是这个镜像，要特殊的来做。

GPU 参考 <https://blog.openshift.com/how-to-use-gpus-with-deviceplugin-in-openshift-3-10/>

## harbor 安装

客户要求装一个harbor。但是harbor默认写死了/data，和我们数据盘冲突，需要改一个目录。

需要修改prepare，和各个yml。本项目相关目录下面，已经改好了一个版本，复制到服务器上面就可以了。

在运行之前，把cert文件复制到 /data/cert 文件加下面。另外，不装clair了，似乎需要联网下载最新的cve数据。

```bash
./prepare --with-notary --with-chartmuseum --with-clair
./install.sh --with-notary --with-chartmuseum --with-clair

./prepare --with-notary --with-chartmuseum
./install.sh --with-notary --with-chartmuseum

docker-compose -f ./docker-compose.yml -f ./docker-compose.notary.yml -f ./docker-compose.chartmuseum.yml -f ./docker-compose.clair.yml down -v

docker-compose -f ./docker-compose.yml -f ./docker-compose.notary.yml -f ./docker-compose.chartmuseum.yml  down -v


docker build -t redhat/harborclient .

docker run --rm \
 -e HARBOR_USERNAME="admin" \
 -e HARBOR_PASSWORD="Harbor12345" \
 -e HARBOR_PROJECT=1 \
 -e HARBOR_URL="https://registry.redhat.ren" \
 redhat/harborclient harbor info \
 openshift3 rhel7 cloudforms46 rhgs3 jboss-amq-6 jboss-datagrid-7 jboss-datavirt-6 jboss-decisionserver-6 jboss-processserver-6 jboss-eap-6 jboss-eap-7 jboss-webserver-3 rhscl redhat-sso-7 redhat-openjdk-18 gitlab nfvpe centos kubevirt nvidia mirrorgooglecontainers krystism coreos
```

在harbor中创建项目： openshift3 rhel7 cloudforms46 rhgs3 jboss-amq-6 jboss-datagrid-7  等

## ssh 免密登录

```bash
for i in master infra node1 node2 node4 registry; do ssh-copy-id $i.redhat.ren; done;

for i in master infra node1 node2 node4 registry; do ssh $i.redhat.ren 'date'; done

```

## ansible-console

以下内容，不能全部执行，根据需要自取。

```bash
ansible-console --private-key ~/.ssh/id_rsa.redhat cmcc -u root

copy src=./hosts dest=/etc/hosts

yum_repository name=ftp description=ftp baseurl=ftp://yum.redhat.ren/data gpgcheck=no state=present

yum name=byobu

timezone name=Asia/Shanghai

file path=/data/docker state=directory
file src=/data/docker dest=/var/lib/docker state=link

yum name=nc,net-tools,ansible,iptables-services,ncdu,lftp,byobu,glances,htop,lsof,ntpdate,bash-completion,wget,nmon,vim,httpd-tools,fail2ban,unzip,git,bind-utils,bridge-utils,lrzsz,docker,openshift-ansible,docker-compose,glusterfs-fuse

yum name=ansible state=absent
yum name=ansible-2.6.13-1.el7ae,openshift-ansible

systemd name=docker state=stopped enabled=no

file path=/data/docker state=absent
file path=/data/docker state=directory

# rhel下面，改docker的数据目录，由于selinux的限制，不能做软连接。
# copy src=./sysconfig/docker dest=/etc/sysconfig/docker

systemd name=docker state=started enabled=yes

lineinfile path=/etc/sysconfig/docker regexp="^INSECURE_REGISTRY" state=absent

lineinfile path=/etc/ssh/sshd_config regexp="^UseDNS" line="UseDNS no" insertafter=EOF state=present
systemd name=sshd state=restarted enabled=yes

shell semanage fcontext -a -t container_var_lib_t "/data/docker(/.*)?"
shell semanage fcontext -a -t container_share_t "/data/docker/overlay2(/.*)?"
shell restorecon -r /data/docker

systemd name=docker state=stopped enabled=no
file path=/var/lib/docker state=absent
file path=/var/lib/docker state=directory
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
ansible-playbook -v -i hosts-3.11.69 /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -v -i hosts-3.11.69 /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -i hosts-3.11.69 /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml

# if uninstall, on each glusterfs nodes, run
vgremove -f $(vgs | tail -1 | awk '{print $1}')
pvremove /dev/sdb2

htpasswd -cb /etc/origin/master/htpasswd admin  password

oc adm policy add-cluster-role-to-user cluster-admin admin
oc adm policy remove-cluster-role-from-user cluster-admin admin
```

## kubevirt

```bash
yum install -y virt-install virt-top

# with ansible
yum name=virt-install,virt-top
shell virt-host-validate qemu

oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-privileged
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-controller
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-apiserver

oc apply -f kubevirt.yaml
oc delete -f kubevirt.yaml
```