#!/usr/bin/env bash

set -e
set -x

var_date=$(date '+%Y.%m.%d.%H%M')
echo $var_date
export var_major_version='4.6'
echo ${var_major_version}

# https://docs.openshift.com/container-platform/4.6/operators/admin/olm-restricted-networks.html

cd /data/ocp4
/bin/rm -rf /data/ocp4/operator
/bin/rm -f operator.ok.list operator.failed.list
mkdir -p /data/ocp4/operator/manifests
mkdir -p /data/ocp4/operator/tgz
cd /data/ocp4/operator/

# oc adm catalog build --filter-by-os='linux/amd64' \
#     --appregistry-org redhat-operators \
#     --from=registry.redhat.io/openshift4/ose-operator-registry:v${var_major_version} \
#     --to=docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-$var_date 

# oc adm catalog mirror \
#     registry.redhat.io/redhat/redhat-operator-index:v4.6 \
#     registry.redhat.ren:5443/ocp-operator \
#     --filter-by-os='linux/amd64' \
#     --manifests-only

skopeo copy \
    docker://registry.redhat.io/redhat/redhat-operator-index:v4.6 \
    docker://docker.io/wangzheng422/operator-catalog:redhat-${var_major_version}-$var_date

oc adm catalog build --filter-by-os='linux/amd64' \
    --appregistry-org certified-operators \
    --from=registry.redhat.io/openshift4/ose-operator-registry:v${var_major_version} \
    --to=docker.io/wangzheng422/operator-catalog:certified-${var_major_version}-$var_date  

oc adm catalog build --filter-by-os='linux/amd64' \
    --appregistry-org community-operators \
    --from=registry.redhat.io/openshift4/ose-operator-registry:v${var_major_version} \
    --to=docker.io/wangzheng422/operator-catalog:community-${var_major_version}-$var_date  

oc adm catalog build --filter-by-os='linux/amd64' \
    --appregistry-org redhat-marketplace \
    --from=registry.redhat.io/openshift4/ose-operator-registry:v${var_major_version} \
    --to=docker.io/wangzheng422/operator-catalog:redhat-marketplace-${var_major_version}-$var_date  

echo $var_date
echo ${var_major_version}
