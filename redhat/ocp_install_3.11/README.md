# openshift 3.11.69 离线安装

## 机器规划

192.168.253.21  master.wander.ren yum.wander.ren registry.wander.ren
192.168.253.22  node1.wander.ren
192.168.253.23  node2.wander.ren

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

yum -y install htop
```

GPU相关的包的源也装上

```bash
yum install -y https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.2.88-1.x86_64.rpm

curl -so /etc/yum.repos.d/nvidia-container-runtime.repo https://nvidia.github.io/nvidia-container-runtime/centos7/nvidia-container-runtime.repo
```

开始制作镜像安装源吧

```bash
reposync -n -d -l -m
createrepo ./
```

## 准备docker镜像

在一台centos云主机上面（合适的地理位置），安装docker，然后运行 pull-images.sh，会自动下载镜像，并且打包。

写这个脚本，是因为发现官方的镜像，有一些版本标签不对，需要手动的调整，需要的话，修改 config.sh

## 主机IP地址

```bash

timedatectl set-timezone Asia/Shanghai

hostnamectl set-hostname master.wander.ren
nmcli connection modify eth0 ipv4.addresses 192.168.253.21/24
nmcli connection modify eth0 ipv4.gateway 192.168.253.2
nmcli connection modify eth0 ipv4.dns 192.168.253.21
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

hostnamectl set-hostname node1.wander.ren
nmcli connection modify eth0 ipv4.addresses 192.168.253.22/24
nmcli connection modify eth0 ipv4.gateway 192.168.253.2
nmcli connection modify eth0 ipv4.dns 192.168.253.21
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

hostnamectl set-hostname node2.wander.ren
nmcli connection modify eth0 ipv4.addresses 192.168.253.23/24
nmcli connection modify eth0 ipv4.gateway 192.168.253.2
nmcli connection modify eth0 ipv4.dns 192.168.253.21
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

cat << EOF >> /etc/hosts

192.168.253.21  master.wander.ren yum.wander.ren registry.wander.ren
192.168.253.22  node1.wander.ren
192.168.253.23  node2.wander.ren

EOF
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
baseurl=ftp://yum.wander.ren/data
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

# 一些基础的包
yum -y update
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion vim lrzsz unzip docker htop

# yum上面装
yum -y install docker-distribution

```

## registry安装

```bash
# yum上面装
yum -y install docker-distribution

mkdir /etc/crts/
cp fullchain1.pem /etc/crts/wander.ren.crt
cp privkey1.pem /etc/crts/wander.ren.key

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
       certificate: /etc/crts/wander.ren.crt
       key: /etc/crts/wander.ren.key
EOF

systemctl daemon-reload
systemctl restart docker-distribution

```