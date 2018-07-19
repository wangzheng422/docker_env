#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

# es
source ./es/deploy.sh

# filebeat
source ./filebeat/deploy.sh

# cenos
source ../centos/base.sh

# hadoop
source ./hadoop/base.sh
source ./hadoop/deploy.sh

# kafka
source ./kafka/kafka-connect/deploy.sh

# hue
source ./hue/deploy.sh

# flume
source ./flume/docker/base.sh
source ./flume/deploy.sh


# docker save elasticsearch:wzh | gzip -c > tmp/elasticsearch.wzh.tgz
# docker save filebeat:wzh | gzip -c > tmp/filebeat.wzh.tgz
# docker save centos:wzh | gzip -c > tmp/centos.wzh.tgz
# docker save hadoop:base | gzip -c > tmp/hadoop.bases.tgz
# docker save hadoop:wzh | gzip -c > tmp/hadoop.wzh.tgz
# docker save cp-kafka-connect:wzh | gzip -c > tmp/cp-kafka-connect.wzh.tgz
# docker save hue:wzh | gzip -c > tmp/hue.wzh.tgz
# docker save flume:build | gzip -c > tmp/flume.build.tgz
# docker save flume:wzh | gzip -c > tmp/flume.wzh.tgz
