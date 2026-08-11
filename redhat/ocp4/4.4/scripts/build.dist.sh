#!/usr/bin/env bash

set -e
set -x

# export BUILDNUMBER="4.2.13"
# stable 4.3.5
build_number_list=$(cat << EOF
4.4.15
EOF
)

export var_date='2020-06-08'
echo $var_date
export var_major_version='4.4'
echo ${var_major_version}

# export MIRROR_DIR='/data/mirror_dir'
# mkdir -p ${MIRROR_DIR}

wget -O image.mirror.fn.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/image.mirror.fn.sh

wget -O image.mirror.install.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/image.mirror.install.sh

wget -O image.registries.conf.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/image.registries.conf.sh

wget -O install.image.list https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/install.image.list

wget -O add.image.load.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/add.image.load.sh

wget -O add.image.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/add.image.sh

wget -O demos.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/4.4/scripts/demos.sh

# podman login registry.redhat.ren -u a -p a

mkdir -p /data/ocp4
cd /data/ocp4
# wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.2/release.txt

# export BUILDNUMBER=$(cat release.txt | grep 'Name:' | awk '{print $NF}')

install_build() {
    BUILDNUMBER=$1
    echo ${BUILDNUMBER}

    rm -rf /data/ocp4/${BUILDNUMBER}
    mkdir -p /data/ocp4/${BUILDNUMBER}
    cd /data/ocp4/${BUILDNUMBER}

    wget -O release.txt https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BUILDNUMBER}/release.txt

    wget -O openshift-client-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BUILDNUMBER}/openshift-client-linux-${BUILDNUMBER}.tar.gz
    wget -O openshift-install-linux-${BUILDNUMBER}.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BUILDNUMBER}/openshift-install-linux-${BUILDNUMBER}.tar.gz

    tar -xzf openshift-client-linux-${BUILDNUMBER}.tar.gz -C /usr/local/sbin/
    tar -xzf openshift-install-linux-${BUILDNUMBER}.tar.gz -C /usr/local/sbin/

    export OCP_RELEASE=${BUILDNUMBER}
    export LOCAL_REG='registry.redhat.ren:5443'
    export LOCAL_REPO='ocp4/openshift4'
    export UPSTREAM_REPO='openshift-release-dev'
    export LOCAL_SECRET_JSON="/data/pull-secret.json"
    export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
    export RELEASE_NAME="ocp-release"

    oc adm release mirror -a ${LOCAL_SECRET_JSON} \
    --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 \
    --to-release-image=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE} \
    --to=${LOCAL_REG}/${LOCAL_REPO}

    # oc adm release extract --command=openshift-install "${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}"

    # oc adm release mirror -a ${LOCAL_SECRET_JSON} \
    # --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 \
    # --to-dir=${MIRROR_DIR}

    # oc image mirror --dir=mirror file://ocp4/openshift4/release:* registry.redhat.ren:5443/ocp4/openshift4 --registry-config=/root/merged_pullsecret.json

    # oc adm release mirror -a ${LOCAL_SECRET_JSON} \
    # --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-s390 \
    # --to-release-image=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE} \
    # --to=${LOCAL_REG}/${LOCAL_REPO}

}

while read -r line; do
    install_build $line
done <<< "$build_number_list"

cd /data/ocp4

wget --recursive --no-directories --no-parent https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.4/latest/

# wget --recursive --no-directories --no-parent https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.2/latest/

wget -O ocp4-upi-helpernode.zip https://github.com/wangzheng422/ocp4-upi-helpernode/archive/master.zip

wget -O docker_env.zip https://github.com/wangzheng422/docker_env/archive/master.zip

wget -O agnosticd.zip https://github.com/wangzheng422/agnosticd/archive/wzh-ccn-ocp-4.4.zip

# wget -O filetranspiler-master.zip https://github.com/wangzheng422/filetranspiler/archive/master.zip

podman pull quay.io/wangzheng422/filetranspiler
podman save quay.io/wangzheng422/filetranspiler | pigz -c > filetranspiler.tgz

podman pull docker.io/library/registry:2
podman save docker.io/library/registry:2 | pigz -c > registry.tgz

oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-${var_date} ${LOCAL_REG}/docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-${var_date}
oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:certified-${var_major_version}-${var_date} ${LOCAL_REG}/docker.io/wangzheng422/operator-catalog:certified-${var_major_version}-${var_date}
oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:community-${var_major_version}-${var_date} ${LOCAL_REG}/docker.io/wangzheng422/operator-catalog:community-${var_major_version}-${var_date}

# /bin/rm -f pull-secret.json

# cd /root
# https://blog.csdn.net/ffzhihua/article/details/85237411
# wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
# rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem

cd /data/ocp4
# download additinal images
# scp files/4.2/docker_image/* 

# yum -y install jq python3-pip pigz docker
# pip3 install yq

# systemctl start docker

# docker login -u ****** -p ******** registry.redhat.io
# docker login -u ****** -p ******** registry.access.redhat.com
# docker login -u ****** -p ******** registry.connect.redhat.com

# podman login -u ****** -p ******** registry.redhat.io
# podman login -u ****** -p ******** registry.access.redhat.com
# podman login -u ****** -p ******** registry.connect.redhat.com

# operator images
# podman run -d --name catalog-fs --entrypoint "tail" docker.io/wangzheng422/operator-catalog:fs-$var_date -f /dev/null
# podman cp catalog-fs:/operator.image.list.uniq /data/ocp4/
# podman rm -fv catalog-fs

# 以下命令要运行 2-3个小时，耐心等待。。。
bash image.mirror.install.sh

# some github, and so on
bash demos.sh

# build operator catalog
oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp-operator 
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-redhat.txt

oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:certified-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp-operator 
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-certified.txt

oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:community-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp-operator 
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-community.txt

bash image.registries.conf.sh

/bin/rm -f index.html*

cd /data
# tar cf - registry/ | pigz -c > registry.tgz 

# cd /data/ocp4
# bash image.mirror.sh
# cd /data
# tar cf - registry/ | pigz -c > registry.with.operator.image.tgz  

# cd /data/ocp4
# bash image.mirror.sample.sh
# cd /data
# tar cf - registry/ | pigz -c > registry.full.with.sample.tgz 

# cd /data
# tar cf - ocp4/ | pigz -c > ocp4.tgz 

# split -b 10G registry.with.operator.image.tgz registry.
# find /data -maxdepth 1 -type f -exec sha256sum {} \;
# echo "$build_number_list" > versions.txt
# find /data -maxdepth 1 -type f -exec sha256sum {} \; > checksum.txt

# find ./ -maxdepth 1 -name "*.tgz" -exec skicka upload {}  /"zhengwan.share/shared_docs/2020.02/ocp.ccn.4.3.3/" \;
# find ./ -maxdepth 1 -name "*.txt" -exec skicka upload {}  /"zhengwan.share/shared_docs/2020.02/ocp.ccn.4.3.3/" \;

