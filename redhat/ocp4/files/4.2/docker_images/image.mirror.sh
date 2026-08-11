#!/usr/bin/env bash

set -e
set -x

# /bin/rm -f pull.image.failed.list pull.image.ok.list yaml.image.ok.list pull.sample.image.ok.list yaml.sample.image.ok.list pull.sample.image.failed.list

# export OCP_RELEASE=${BUILDNUMBER}
# export LOCAL_REG='registry.redhat.ren'
# export LOCAL_REPO='ocp4/openshift4'
# export UPSTREAM_REPO='openshift-release-dev'
# export LOCAL_SECRET_JSON="pull-secret.json"
# export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
# export RELEASE_NAME="ocp-release"

source image.mirror.fn.sh

/bin/cp -f /data/ocp4/install.image.list install.image.list.tmp

cat /data/ocp4/operator.image.list >> install.image.list.tmp

cat install.image.list.tmp | sort | uniq > /data/ocp4/install.image.list.tmp.uniq

# while read -r line; do

#     mirror_sample_image $line

# done < sample.image.list

while read -r line; do

    mirror_image $line

done < install.image.list.tmp.uniq

# while read -r line; do
#     mirror_image $line
# done < install.image.list

# while read -r line; do
#     mirror_image $line
# done < operator.image.list.uniq

cat yaml.image.ok.list | sort | uniq > yaml.image.ok.list.uniq



