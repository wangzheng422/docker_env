#!/usr/bin/env bash

set -e
set -x

cd /data/ccn

var_date=$(date '+%Y-%m-%d')
echo $var_date

podman stop gogs
podman rm -fv gogs

tar cf - ./gogs | pigz -c > gogs.tgz
buildah from --name onbuild-container docker.io/library/centos:centos7
buildah copy onbuild-container gogs.tgz /
buildah umount onbuild-container 
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/gogs-fs:$var_date
# buildah rm onbuild-container
buildah push docker.io/wangzheng422/gogs-fs:$var_date

podman stop nexus
podman rm -fv nexus

tar cf - ./nexus | pigz -c > nexus.tgz 
buildah from --name onbuild-container docker.io/library/centos:centos7
buildah copy onbuild-container nexus.tgz /
buildah umount onbuild-container 
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/nexus-fs:$var_date
# buildah rm onbuild-container
buildah push docker.io/wangzheng422/nexus-fs:$var_date

podman image prune

