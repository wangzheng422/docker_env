# openshift 3.11.81 离线安装

based on <https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html> and <http://ksoong.org/docs/content/openshift/install/>

以下文章中的命令，不是安装时候的顺序执行命令，请搞懂命令的含义，按照自己的需要取用。

## 机器规划

```bash

localectl set-locale LANG=en_US.UTF-8

cat << EOF > /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.122.111  it-m1 it-m1.redhat.ren it-registry it-registry.redhat.ren it-yum it-yum.redhat.ren
192.168.122.112  it-m2 it-m2.redhat.ren
192.168.122.113  it-m3 it-m3.redhat.ren
192.168.122.114  it-n1 it-n1.redhat.ren
192.168.122.115  it-n2 it-n2.redhat.ren
192.168.122.116  it-n3 it-n3.redhat.ren

192.168.122.117  it-lb it-lb.redhat.ren
192.168.122.118  it-infra it-infra.redhat.ren

192.168.122.119  it-c1 it-c1.redhat.ren

192.168.122.120  it-c2 it-c2.redhat.ren

# 192.168.122.118 *.it-apps.redhat.ren
# 192.168.122.119 *.it-c1-apps.redhat.ren
# 192.168.122.120 *.it-c2-apps.redhat.ren

# 10.252.166.109  it-paas it-paas.redhat.ren

EOF


```

## 准备docker镜像

在一台centos云主机上面（合适的地理位置），安装docker，然后运行 pull-images.sh，会自动下载镜像，并且打包。

写这个脚本，是因为发现官方的镜像，有一些版本标签不对，需要手动的调整，需要的话，修改 config.sh

下载的镜像，总共12G左右

## 主机IP地址

```bash

timedatectl set-timezone Asia/Shanghai

# 192.168.122.111
hostnamectl set-hostname it-m1.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.112
hostnamectl set-hostname it-m2.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.113
hostnamectl set-hostname it-m3.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.114
hostnamectl set-hostname it-n1.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.115
hostnamectl set-hostname it-n2.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.116
hostnamectl set-hostname it-n3.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.117
hostnamectl set-hostname it-lb.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.118
hostnamectl set-hostname it-infra.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.119
hostnamectl set-hostname it-c1.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

# 192.168.122.120
hostnamectl set-hostname it-c2.redhat.ren
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv4.dns 192.168.122.111
nmcli connection modify eth0 connection.autoconnect yes
nmcli connection reload
nmcli connection up eth0

lshw -class network

lspci | egrep -i --color 'network|ethernet'

```

## ntp 时间源

服务器配置和客户端不一样，服务器需要把本地时钟作为源。一般不用搞，安装过程自己搞定，但是主机的时间偏差实在太大，就还是先搞一下吧。。。

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
baseurl=ftp://it-yum.redhat.ren/data
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
            -v "/Users/wzh/Documents/redhat/tools/it-apps.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/it-apps.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.it-apps.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/it-apps.redhat.ren/fullchain1.pem it-apps.redhat.ren.fullchain1.pem
cp ./etc/archive/it-apps.redhat.ren/privkey1.pem it-apps.redhat.ren.privkey1.pem
cp ./etc/archive/it-apps.redhat.ren/chain1.pem it-apps.redhat.ren.chain1.pem

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

## 准备DNS

```bash

yum -y install dnsmasq

cat  > /etc/dnsmasq.d/openshift-cluster.conf << EOF
local=/redhat.ren/
address=/it-m1.redhat.ren/192.168.122.111
address=/it-m2.redhat.ren/192.168.122.112
address=/it-m3.redhat.ren/192.168.122.113
address=/it-n1.redhat.ren/192.168.122.114
address=/it-n2.redhat.ren/192.168.122.115
address=/it-n3.redhat.ren/192.168.122.116
address=/it-lb.redhat.ren/192.168.122.117
address=/it-infra.redhat.ren/192.168.122.118
address=/it-registry.redhat.ren/192.168.122.111
address=/it-yum.redhat.ren/192.168.122.111
address=/it-c1.redhat.ren/192.168.122.119
address=/it-c2.redhat.ren/192.168.122.120
address=/.it-apps.redhat.ren/192.168.122.118
address=/.it-c1-apps.redhat.ren/192.168.122.119
address=/.it-c2-apps.redhat.ren/192.168.122.120

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

3.11的文档说，nfs已经不推荐了，让用glusterfs，但是没办法，继续用把。

```bash
# 3.11的文档说，nfs已经不推荐了，让用glusterfs
yum -y install nfs-utils rpcbind

systemctl enable nfs-server

firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload

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


## ssh 免密登录

```bash
for i in it-m1 it-m2 it-m3 it-n1 it-n2 it-n3 it-lb it-infra it-c1 it-c2; do ssh-copy-id $i.redhat.ren; done;

for i in it-m1 it-m2 it-m3 it-n1 it-n2 it-n3 it-lb it-infra it-c1 it-c2; do ssh $i.redhat.ren 'date'; done

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
ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/openshift-metrics/config.yml

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


