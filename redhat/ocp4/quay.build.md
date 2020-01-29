# Quay running in local dev mode

https://github.com/zhangchl007/quay

https://github.com/quay/quay/blob/master/docs/development-container.md

https://access.redhat.com/documentation/en-us/red_hat_quay/3/html-single/deploy_red_hat_quay_-_basic/index

https://www.cnblogs.com/ericnie/p/12233269.html

```bash
cat << EOF >>  /etc/hosts
207.246.103.211 registry.redhat.ren clair.redhat.ren
EOF

yum install -y podman buildah skopeo

podman rm -fv $(podman ps -qa)
podman volume prune -f
podman pod rm -fa

podman pod create --name quay -p 5443:8443 

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
export MYSQL_CONTAINER_NAME=quay-mysql
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
    --pod quay \
    -v /data/quay/lib/mysql:/var/lib/mysql/data:Z \
    registry.access.redhat.com/rhscl/mysql-57-rhel7

mkdir -p /data/quay/lib/redis
chmod 777 /data/quay/lib/redis
podman run -d --restart=always \
    --pod quay \
    --privileged=true \
    --name quay-redis \
    -v  /data/quay/lib/redis:/var/lib/redis/data:Z \
    registry.access.redhat.com/rhscl/redis-32-rhel7

# test mysql
# yum install -y mariadb
# mysql -h registry.redhat.ren -u root --password=q98u335musckfqxe

# quay config
# podman login -u="redhat+quay" ****************
podman run --privileged=true \
    --name quay-config \
    --pod quay \
    --add-host mysql:127.0.0.1 \
    --add-host redis:127.0.0.1 \
    -d quay.io/redhat/quay:v3.2.0 config ka5tr4g3quzrwkq4
# login: quayconfig  /  ka5tr4g3quzrwkq4
# quay admin:  admin   /   5a4ru36a8zfr1gp8
# clair: security_scanner
# key id: da5a87dd2cf8e0ac62a56d3611d33a1f4b9f8d7e8a5aed7a4f5612ae549ab82f

# cp quay-config.tar.gz /data/quay/config/
cd /data/quay/config/
# wget https://github.com/wangzheng422/docker_env/raw/dev/redhat/ocp4/files/4.2/quay/quay-config.tar.gz
tar xvf quay-config.tar.gz

podman run --restart=always \
    --sysctl net.core.somaxconn=4096 \
    --privileged=true \
    --name quay-master \
    --pod quay \
    --add-host mysql:127.0.0.1 \
    --add-host redis:127.0.0.1 \
    -v /data/quay/config:/conf/stack:Z \
    -v /data/quay/storage:/datastorage:Z \
    -d quay.io/redhat/quay:v3.2.0


podman stop quay-master
podman stop quay-redis
podman stop quay-mysql

cd /data
tar zcf quay.tgz quay/

buildah from --name onbuild-container docker.io/library/centos:centos7
buildah copy onbuild-container quay.tgz /
buildah umount onbuild-container 
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/quay-fs:3.2.0-init
# buildah rm onbuild-container
buildah push docker.io/wangzheng422/quay-fs:3.2.0-init


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