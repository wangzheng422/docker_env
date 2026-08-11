#!/usr/bin/env bash

set -e
set -x

# docker build -t centos:wzh ./

docker run --rm -it --name=centos -v /root/work/centos:/mnt centos:wzh bash -c "yum -y update; cd /mnt; reposync -d ./"