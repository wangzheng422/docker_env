# quay.redhat.ren

https://github.com/zhangchl007/quay

https://github.com/quay/quay/blob/master/docs/development-container.md

https://access.redhat.com/documentation/en-us/red_hat_quay/3/html-single/deploy_red_hat_quay_-_basic/index

https://www.cnblogs.com/ericnie/p/12233269.html

```bash
cat << EOF >>  /etc/hosts
207.246.103.211 registry.redhat.ren clair.redhat.ren
EOF

yum install -y podman

rm -rf /data/quay
mkdir -p /data/quay/storage
mkdir -p /data/quay/config
mkdir -p /data/quay/git
cd /data/quay/git

# yum install -y git
# git clone https://github.com/quay/quay
# cd /data/quay/git/quay
# git checkout 3.2.0-release

firewall-cmd --permanent --zone=public --add-port=5443/tcp
firewall-cmd --reload

mkdir -p /data/quay/lib/mysql
chmod 777 /data/quay/lib/mysql
export MYSQL_CONTAINER_NAME=mysql
export MYSQL_DATABASE=enterpriseregistrydb
export MYSQL_PASSWORD=zvbk3fzp5f5m2a8j
export MYSQL_USER=quayuser
export MYSQL_ROOT_PASSWORD=q98u335musckfqxe

podman run \
    --detach \
    --restart=always \
    --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
    --env MYSQL_USER=${MYSQL_USER} \
    --env MYSQL_PASSWORD=${MYSQL_PASSWORD} \
    --env MYSQL_DATABASE=${MYSQL_DATABASE} \
    --name ${MYSQL_CONTAINER_NAME} \
    --privileged=true \
    --publish 3306:3306 \
    -v /data/quay/lib/mysql:/var/lib/mysql/data:Z \
    registry.access.redhat.com/rhscl/mysql-57-rhel7

mkdir -p /data/quay/lib/redis
chmod 777 /data/quay/lib/redis
podman run -d --restart=always -p 6379:6379 \
    --privileged=true \
    -v  /data/quay/lib/redis:/var/lib/redis/data:Z \
    registry.access.redhat.com/rhscl/redis-32-rhel7

# quay config
podman login -u="redhat+quay" ****************
podman run --privileged=true -p 5443:8443 -d quay.io/redhat/quay:v3.2.0 config ka5tr4g3quzrwkq4
# login: quayconfig  /  ka5tr4g3quzrwkq4
# quay admin:  admin   /   5a4ru36a8zfr1gp8
# clair: security_scanner
# key id: abdd5f328a99695aa861452d81a22086569a2f7a64baedcfca6c6f4797c48228

# cp quay-config.tar.gz /data/quay/config/
cd  /data/quay/config/
tar xvf quay-config.tar.gz

podman run --restart=always -p 5443:8443 -p 5080:8080 \
   --sysctl net.core.somaxconn=4096 \
   --privileged=true \
   -v /data/quay/config:/conf/stack:Z \
   -v /data/quay/storage:/datastorage:Z \
   -d quay.io/redhat/quay:v3.2.0

```


```bash
git clone https://github.com/zhangchl007/quay

ENCRYPTED_ROBOT_TOKEN_MIGRATION_PHASE=new-installation

bash self-cert-generate.sh redhat.ren quay.redhat.ren
sudo sh pre-quaydeploy.sh

docker-compose  -f docker-compose.config.yml  up -d

firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --reload
firewall-cmd --list-all

# username/password: quayconfig / redhat


```