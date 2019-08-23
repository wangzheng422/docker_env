#

```bash
hostnamectl set-hostname rhel-wzh.redhat.ren

mkdir /etc/crts/ && cd /etc/crts
openssl req \
   -newkey rsa:2048 -nodes -keyout redhat.ren.key \
   -x509 -days 3650 -out redhat.ren.crt -subj \
   "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.redhat.ren"

cp /etc/crts/redhat.ren.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
systemctl restart docker

yum -y install docker-distribution

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
    addr: :443
    tls:
       certificate: /etc/crts/redhat.ren.crt
       key: /etc/crts/redhat.ren.key
EOF

systemctl daemon-reload
systemctl restart docker-distribution
systemctl enable docker-distribution

firewall-cmd --get-active-zones
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

firewall-cmd --list-all

cat << EOF >>/etc/sysconfig/docker

ADD_REGISTRY='--add-registry registry.redhat.io'

EOF

systemctl restart docker
```