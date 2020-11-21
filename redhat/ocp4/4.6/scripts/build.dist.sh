#!/usr/bin/env bash

set -e
set -x

build_number_list=$(cat << EOF
4.6.5
EOF
)

# params for operator hub images
export var_date='2020.11.21.1108'
echo $var_date
export var_major_version='4.6'
echo ${var_major_version}

wget -O image.mirror.fn.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/image.mirror.fn.sh

wget -O image.mirror.install.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/image.mirror.install.sh

wget -O image.registries.conf.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/image.registries.conf.sh

wget -O install.image.list https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/install.image.list

wget -O add.image.load.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/add.image.load.sh

wget -O add.image.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/add.image.sh

wget -O demos.sh https://raw.githubusercontent.com/wangzheng422/docker_env/dev/redhat/ocp4/${var_major_version}/scripts/demos.sh

mkdir -p /data/ocp4/clients
# client for camle-k
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive https://mirror.openshift.com/pub/openshift-v4/clients/camel-k/latest/

# client for helm
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/

# client for pipeline
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive https://mirror.openshift.com/pub/openshift-v4/clients/pipeline/latest/

# client for serverless
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive https://mirror.openshift.com/pub/openshift-v4/clients/serverless/latest/

# coreos-installer
wget  -nd -np -e robots=off --reject="index.html*" -P /data/ocp4/clients --recursive https://mirror.openshift.com/pub/openshift-v4/clients/coreos-installer/latest/

mkdir -p /data/ocp4
/bin/rm -f /data/finished
cd /data/ocp4

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

}

while read -r line; do
    install_build $line
done <<< "$build_number_list"

cd /data/ocp4

wget --recursive --no-directories --no-parent -e robots=off --accept="*live*,*installer*"  https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${var_major_version}/latest/

wget -O ocp4-upi-helpernode.zip https://github.com/wangzheng422/ocp4-upi-helpernode/archive/master.zip

wget -O docker_env.zip https://github.com/wangzheng422/docker_env/archive/dev.zip

wget -O agnosticd.zip https://github.com/wangzheng422/agnosticd/archive/wzh-ccn-ocp-4.4.zip

podman pull quay.io/wangzheng422/filetranspiler
podman save quay.io/wangzheng422/filetranspiler | pigz -c > filetranspiler.tgz

podman pull docker.io/library/registry:2
podman save docker.io/library/registry:2 | pigz -c > registry.tgz

oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:redhat-${var_major_version}-${var_date}
oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:certified-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:certified-${var_major_version}-${var_date}
oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:community-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:community-${var_major_version}-${var_date}
oc image mirror --filter-by-os='linux/amd64' docker.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-${var_date} ${LOCAL_REG}/ocp4/operator-catalog:redhat-marketplace-${var_major_version}-${var_date}

cd /data/ocp4

# 以下命令要运行 2-3个小时，耐心等待。。。
# bash image.mirror.install.sh

# some github, and so on
bash demos.sh

# build operator catalog
oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-redhat.txt
sed -i 's/=.*//g' mapping-redhat.txt

oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:certified-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-certified.txt
sed -i 's/=.*//g' mapping-certified.txt

oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:community-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-community.txt
sed -i 's/=.*//g' mapping-community.txt

oc adm catalog mirror --filter-by-os='linux/amd64' \
    docker.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-$var_date \
    registry.redhat.ren:5443/ocp4 \
    --manifests-only
/bin/cp -f operator-catalog-manifests/mapping.txt mapping-redhat-marketplace.txt
sed -i 's/=.*//g' mapping-redhat-marketplace.txt

bash image.registries.conf.sh registry.redhat.ren:5443

/bin/rm -f index.html*
/bin/rm -f operator-catalog-manifests

cd /data

var_finish_date=$(date '+%Y-%m-%d-%H%M')
echo $var_finish_date > /data/finished

