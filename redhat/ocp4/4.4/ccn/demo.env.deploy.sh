#!/usr/bin/env bash

set -e
set -x

export LOCAL_REG='registry.redhat.ren:5443/'
# export LOCAL_REG=''
gogs_var_date='2020-02-17'
nexus_var_date='2020-01-14'

mkdir -p /data/ccn

podman stop gogs || true
podman rm -fv gogs || true
podman stop nexus || true
podman rm -fv nexus || true
podman stop etherpad || true
podman rm -fv etherpad || true

podman image prune -a

firewall-cmd --permanent --add-port=10080/tcp
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --permanent --add-port=9001/tcp
firewall-cmd --reload
firewall-cmd --list-all

# restore gogs-fs
cd /data/ccn
rm -rf /data/ccn/gogs
podman run -d --name gogs-fs --entrypoint "tail" ${LOCAL_REG}docker.io/wangzheng422/gogs-fs:$gogs_var_date -f /dev/null
podman cp gogs-fs:/gogs.tgz /data/ccn/
tar zxf gogs.tgz
podman rm -fv gogs-fs

# try to restore nexus-fs
cd /data/ccn
rm -rf /data/ccn/nexus
podman run -d --name nexus-fs --entrypoint "tail" ${LOCAL_REG}docker.io/wangzheng422/nexus-fs:$nexus_var_date -f /dev/null
podman cp nexus-fs:/nexus.tgz /data/ccn/
tar zxf nexus.tgz ./
podman rm -fv nexus-fs

# firewall-cmd --permanent --add-port=10080/tcp
# firewall-cmd --reload
# firewall-cmd --list-all

podman run -d --name=gogs -p 10022:22 -p 10080:3000 -v /data/ccn/gogs:/data:Z -v /data/ccn/gogs/resolv.conf:/etc/resolv.conf:Z ${LOCAL_REG}docker.io/gogs/gogs

chown -R 200 /data/ccn/nexus

# firewall-cmd --permanent --add-port=8081/tcp
# firewall-cmd --reload
# firewall-cmd --list-all

podman run -d -p 8081:8081 -it --name nexus -v /data/ccn/nexus:/nexus-data:Z ${LOCAL_REG}docker.io/sonatype/nexus3

# cd /data/ccn
# rm -rf /data/ccn/etherpad
mkdir -p /data/ccn/etherpad

chown -R 5001 /data/ccn/etherpad

# firewall-cmd --permanent --add-port=9001/tcp
# firewall-cmd --reload
# firewall-cmd --list-all

podman run -d -p 9001:9001 -it --name etherpad -v /data/ccn/etherpad:/opt/etherpad-lite/var:z ${LOCAL_REG}docker.io/etherpad/etherpad:latest

