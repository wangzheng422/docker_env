# aws based demo system

this is base station

## rhel 安装源准备

```bash
subscription-manager register --username **** --password ********

subscription-manager list --available --all

subscription-manager attach --pool=8a85f99a684d00130168825ec15b1bf4

subscription-manager repos --disable="*"

subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-supplementary-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms" \
    --enable="rhel-7-server-3scale-amp-2.5-rpms" \
    --enable="rhel-7-server-cnv-1.4-tech-preview-rpms"

yum -y install wget yum-utils createrepo docker git
```

## epel

```bash
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -y install ./epel-release-latest-7.noarch.rpm

yum -y install htop byobu ethtool
```

## gpu

这个暂时不做吧

```bash
yum install -y https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-10.1.168-1.x86_64.rpm

curl -so /etc/yum.repos.d/nvidia-container-runtime.repo https://nvidia.github.io/nvidia-container-runtime/centos7/nvidia-container-runtime.repo
```

## download yum

```bash
mkdir -p /data/yum
cd /data/yum
reposync -n -d -l -m
```

## build the ftp server

```bash
yum -y install vsftpd
systemctl start vsftpd
systemctl restart vsftpd
systemctl enable vsftpd

mv /data/yum /var/ftp/yum
# original is default_t
chcon -R -t public_content_t  /var/ftp/yum
# semanage fcontext --list | grep --color 'var/ftp'
# semanage fcontext --add --type public_content_t "/data/yum(/.*)?"
# semanage fcontext --add --type public_content_t "/var/ftp/yum(/.*)?"
# semanage fcontext --delete --type public_content_t "/data/yum(/.*)?"
# semanage fcontext --delete --type public_content_t "/var/ftp/yum(/.*)?"
chcon -t default_t /data

firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload
```

docker login to registry

## ocp components

先pull-images.sh下载镜像。

## 证书

```bash
docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/redhat.ren/fullchain3.pem redhat.ren.fullchain1.pem
cp ./etc/archive/redhat.ren/privkey3.pem redhat.ren.privkey1.pem

docker run -it --rm --name certbot \
            -v "/Users/wzh/Documents/redhat/tools/aws-apps.redhat.ren/etc:/etc/letsencrypt" \
            -v "/Users/wzh/Documents/redhat/tools/aws-apps.redhat.ren/lib:/var/lib/letsencrypt" \
            certbot/certbot certonly  -d "*.aws-apps.redhat.ren" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

cp ./etc/archive/aws-apps.redhat.ren/fullchain1.pem aws-apps.redhat.ren.fullchain1.pem
cp ./etc/archive/aws-apps.redhat.ren/privkey1.pem aws-apps.redhat.ren.privkey1.pem
cp ./etc/archive/aws-apps.redhat.ren/chain1.pem aws-apps.redhat.ren.chain1.pem
```

## 安装docker-registry

```bash
# yum上面装
yum -y install docker-distribution

# 把 Let’s Encrypt 上传到服务器上面
mkdir -p /etc/crts/
cp redhat.ren.fullchain1.pem /etc/crts/redhat.ren.crt
cp redhat.ren.privkey1.pem /etc/crts/redhat.ren.key


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
    addr: :443
    tls:
       certificate: /etc/crts/redhat.ren.crt
       key: /etc/crts/redhat.ren.key
EOF

systemctl daemon-reload
systemctl restart docker-distribution
systemctl enable docker-distribution

# 打开防火墙
firewall-cmd --get-active-zones
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

firewall-cmd --list-all
```

## ntp

```bash
# firewall-cmd --permanent --add-port=123/udp
firewall-cmd --permanent --add-service=ntp
firewall-cmd --reload

firewall-cmd --list-all

cat << EOF >> /etc/chrony.conf

allow 172.31.16.0/20

EOF
systemctl restart chronyd
```

## dns

```bash

cat << EOF > /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.31.17.41  aws-registry aws-registry.redhat.ren aws-yum aws-yum.redhat.ren
172.31.18.62  aws-m1 aws-m1.redhat.ren
172.31.31.155  aws-n1 aws-n1.redhat.ren
172.31.18.239  aws-n2 aws-n2.redhat.ren
172.31.17.7  aws-n3 aws-n3.redhat.ren

# 172.31.18.62 *.aws-apps.redhat.ren

172.31.18.62  aws-paas aws-paas.redhat.ren

EOF



yum -y install dnsmasq

# cat  > /etc/dnsmasq.d/openshift-cluster.conf << EOF
# local=/redhat.ren/
# address=/aws-m1.redhat.ren/172.31.18.62
# address=/aws-n1.redhat.ren/192.168.122.114
# address=/aws-n2.redhat.ren/192.168.122.115
# address=/aws-n3.redhat.ren/192.168.122.116
# address=/aws-yum.redhat.ren/192.168.122.116
# address=/.aws-apps.redhat.ren/192.168.122.118

# EOF

# master节点，本次环境没有外网，也没有上级dns，就不用做这里了。
cat > /etc/dnsmasq.d/origin-upstream-dns.conf << EOF 
server=172.31.0.2
EOF

systemctl start dnsmasq.service && systemctl enable dnsmasq.service && systemctl status dnsmasq.service

firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

systemctl restart dnsmasq

```