#!/usr/bin/env bash

export tag="4.2"
export private_repo="vm.redhat.ren"
export major_tag="4.2"
# https://access.redhat.com/articles/2834301
# docker search rhgs3 | grep redhat.io | awk '{print $2}'
# search for openshift, openshift3, fuse7, dotnet, jboss

## 后续导入的时候，要用2个版本号
quay_images=$(cat << EOF
quay.io/openshift/origin-cli:$tag
quay.io/openshift/origin-cli-artifacts:$tag
quay.io/openshift/origin-cluster-samples-operator:$tag
quay.io/openshift/origin-baremetal-installer:$tag
quay.io/openshift/origin-installer:$tag
quay.io/openshift/origin-installer-artifacts:$tag
quay.io/openshift/origin-jenkins:$tag
quay.io/openshift/origin-jenkins-agent-nodejs:$tag
quay.io/openshift/origin-jenkins-agent-maven:$tag
quay.io/openshift/origin-tests:$tag
quay.io/openshift/origin-must-gather:$tag

quay.io/k8scsi/csi-provisioner:v1.3.0
quay.io/k8scsi/csi-attacher:v1.2.0
quay.io/k8scsi/csi-snapshotter:v1.2.0
quay.io/k8scsi/csi-node-driver-registrar:v1.1.0
quay.io/cephcsi/cephcsi:v1.2.1

quay.io/external_storage/nfs-client-provisioner:latest

EOF
)

dockerio_images=$(cat << EOF
docker.io/rook/nfs:master
docker.io/rook/ceph:master
docker.io/ceph/ceph:v14

docker.io/nfvpe/cni-route-override:latest

EOF
)


