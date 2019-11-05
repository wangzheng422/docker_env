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
    --enable="rhel-7-server-ose-4.2-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms" \
    --enable="rhel-7-server-ansible-2.8-rpms" \
    --enable="rhel-7-server-3scale-amp-2.5-rpms" \
    --enable="rhel-7-server-cnv-1.4-tech-preview-rpms" \
    --enable="rhel-7-server-optional-rpms" 

subscription-manager repos --enable="rhel-7-server-openstack-14-rpms"

# subscription-manager repos --enable="rhel-7-server-e4s-optional-rpms"
# subscription-manager repos --disable="rhel-7-server-e4s-optional-rpms"

subscription-manager repos --list-enabled

yum -y install wget yum-utils createrepo docker git 

yum -y install ansible-2.6.17-1.el7ae openshift-ansible

systemctl enable docker
systemctl start docker
```

yum proxy
```bash
cat ~/.ssh/id_rsa.pub
vi ~/.ssh/authorized_keys

cat << EOF >> /etc/yum.conf
proxy=socks5://192.168.253.1:5085
EOF

rm -fr /var/cache/yum/*
yum clean all 
yum -y install deltarpm
yum -y update
```

## ocp 4.2
```bash
cat << EOF > /etc/yum.repos.d/ocp.4.2.repo
[ocp4.2]
name=ocp4.2
baseurl=https://mirror.openshift.com/pub/openshift-v4/dependencies/rpms/4.2-beta/
enabled=1
gpgcheck=0

EOF

```

## epel

```bash
# wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -y install htop byobu ethtool

yum-config-manager --disable epel
```

## gpu

这个要在centos上面做，rhel上面会报证书的错误，以前是不会的，新的rhel版本会报错。

```bash
yum install -y https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-10.1.243-1.x86_64.rpm

# curl -so /etc/yum.repos.d/nvidia-container-runtime.repo https://nvidia.github.io/nvidia-container-runtime/centos7/nvidia-container-runtime.repo

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo

curl -s -L https://nvidia.github.io/nvidia-container-runtime/rhel7.6/nvidia-container-runtime.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo

# update key
DIST=$(sed -n 's/releasever=//p' /etc/yum.conf)
DIST=${DIST:-$(. /etc/os-release; echo $VERSION_ID)}
DIST=7Server
sudo sudo rpm -e gpg-pubkey-f796ecb0
sudo gpg --homedir /var/lib/yum/repos/$(uname -m)/$DIST/*/gpgdir --delete-key f796ecb0
sudo gpg --homedir /var/lib/yum/repos/$(uname -m)/latest/nvidia-docker/gpgdir --delete-key f796ecb0
sudo gpg --homedir /var/lib/yum/repos/$(uname -m)/latest/nvidia-container-runtime/gpgdir --delete-key f796ecb0
sudo gpg --homedir /var/lib/yum/repos/$(uname -m)/latest/libnvidia-container/gpgdir --delete-key f796ecb0
sudo yum makecache

# change /etc/yum.repos.d/nvidia-container-runtime.repo repo_gpgcheck=0
# https://github.com/NVIDIA/nvidia-docker/issues/836
# https://github.com/NVIDIA/nvidia-docker/issues/860
```

## download yum

```bash
mkdir -p /data/yum
cd /data/yum
reposync -n -d -l -m
yum repolist
reposync -n -d -l -m -r rhel-7-server-openstack-14-rpms
createrepo ./

# reposync -r rhel-7-server-e4s-optional-rpms -n -d -l -m

# repotrack -p ./tmp/  openshift-hyperkube-4.2.0

tar -cvf - yum/ | pigz -c > yum.tgz
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
cp /home/ec2-user/down/cert/redhat.ren.fullchain1.pem /etc/crts/redhat.ren.crt
cp /home/ec2-user/down/cert/redhat.ren.privkey1.pem /etc/crts/redhat.ren.key


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
    delete:
        enabled: true
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

chronyc tracking
chronyc sources -v
chronyc sourcestats -v
chronyc makestep
```

## zerotier

https://www.lisenet.com/2016/firewalld-rich-and-direct-rules-setup-rhel-7-server-as-a-router/

https://zerotier.atlassian.net/wiki/spaces/SD/pages/7503890/ZeroTier+to+Amazon+VPC+Gateway

```bash

curl -s 'https://raw.githubusercontent.com/zerotier/download.zerotier.com/master/htdocs/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi

yum -y install firewalld
systemctl enable firewalld
systemctl start firewalld

sysctl net.ipv4.conf.all.forwarding

sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv4.ip_forward=1

cat << EOF > /etc/sysctl.d/ip_forward.conf
net.ipv4.ip_forward=1
EOF


# firewall-cmd --permanent --change-zone=ztnfaahj5u --zone=public
# firewall-cmd --permanent --change-zone=ztnfaahj5u --zone=trusted
# firewall-cmd --permanent --remove-interface=ztnfaahj5u --zone=public
firewall-cmd --permanent --add-interface=ztnfaahj5u --zone=trusted
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload

nmcli d
firewall-cmd --get-active-zones
firewall-cmd --get-default-zone

```

# vim

disable auto indent

:setl noai nocin nosi inde=

# aws cli

```bash
yum -y install python2-pip

pip install awscli --upgrade --user

# cat << EOF >> ~/.bash_profile

# export PATH=~/.local/bin:$PATH

# EOF

aws --version

aws configure

aws ec2 describe-volumes --output text

aws ec2 describe-instances --output table 

# cat << EOF >> ~/.bashrc

# source ~/.bash_profile

# EOF

# ocp-3.11-m1
aws ec2 run-instances --launch-template LaunchTemplateId=lt-0b9f087b945ec9d5c,Version=8

# ocp-3.11-n1
aws ec2 run-instances --launch-template LaunchTemplateId=lt-0a1ea0c9a2b782e08,Version=11

# ocp-3.11-n2
aws ec2 run-instances --launch-template LaunchTemplateId=lt-098beb0c4004751ea,Version=8

# ocp-3.11-n3
aws ec2 run-instances --launch-template LaunchTemplateId=lt-0891c7f965582df2d,Version=9

# ocp-3.11-c2
aws ec2 run-instances --launch-template LaunchTemplateId=lt-0126d8eb82619864b,Version=3

```