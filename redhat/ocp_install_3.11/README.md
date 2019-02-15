# openshift 3.11.69 离线安装

## 机器规划

192.168.253.21  master.wander.ren
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