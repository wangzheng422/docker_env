#!/usr/bin/env bash

set -e
set -x

export LOCAL_REG='registry.redhat.ren'
var_date='2020-01-01'

mkdir -p /data/ccn

podman stop gogs || true
podman rm -fv gogs || true
podman stop nexus || true
podman rm -fv nexus || true

# restore gogs-fs
cd /data/ccn
rm -rf /data/ccn/gogs
podman run -d --name gogs-fs --entrypoint "tail" ${LOCAL_REG}/docker.io/wangzheng422/gogs-fs:$var_date -f /dev/null
podman cp gogs-fs:/gogs.tgz /data/ccn/
tar zxf gogs.tgz
podman rm -fv gogs-fs

# try to restore nexus-fs
cd /data/ccn
rm -rf /data/ccn/nexus
podman run -d --name nexus-fs --entrypoint "tail" ${LOCAL_REG}/docker.io/wangzheng422/nexus-fs:$var_date -f /dev/null
podman cp nexus-fs:/nexus.tgz /data/ccn/
tar zxf nexus.tgz ./
podman rm -fv nexus-fs

firewall-cmd --permanent --add-port=10080/tcp
firewall-cmd --reload
firewall-cmd --list-all

podman run -d --name=gogs -p 10022:22 -p 10080:3000 -v /data/ccn/gogs:/data:Z ${LOCAL_REG}/docker.io/gogs/gogs

chown -R 200 /data/ccn/nexus

firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --reload
firewall-cmd --list-all

podman run -d -p 8081:8081 -it --name nexus -v /data/ccn/nexus:/nexus-data:Z ${LOCAL_REG}/docker.io/sonatype/nexus3
