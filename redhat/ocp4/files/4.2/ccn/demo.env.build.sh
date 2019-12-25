#!/usr/bin/env bash

set -e
set -x

cd /data/ccn

podman stop gogs
podman rm -fv gogs

tar cf - ./gogs | pigz -c > gogs.tgz
buildah from --name onbuild-container registry.redhat.io/ubi7/ubi
buildah copy onbuild-container gogs.tgz /
buildah umount onbuild-container 
buildah commit --format=docker onbuild-container docker.io/wangzheng422/gogs-fs:latest
buildah rm onbuild-container
buildah push docker.io/wangzheng422/gogs-fs:latest

podman stop nexus
podman rm -fv nexus

tar cf - ./nexus | pigz -c > nexus.tgz 
buildah from --name onbuild-container registry.redhat.io/ubi7/ubi
buildah copy onbuild-container nexus.tgz /
buildah umount onbuild-container 
buildah commit --format=docker onbuild-container docker.io/wangzheng422/nexus-fs
buildah rm onbuild-container
buildah push docker.io/wangzheng422/nexus-fs

