#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

# es
source ./es/deploy.sh
docker save elasticsearch:wzh | gzip -c > tmp/elasticsearch.wzh.tgz

# filebeat
source ./filebeat/deploy.sh
docker save filebeat:wzh | gzip -c > tmp/filebeat.wzh.tgz

# cenos
source ../centos/base.sh
docker save centos:wzh | gzip -c > tmp/centos.wzh.tgz

# hadoop
source ./hadoop/base.sh
docker save hadoop:base | gzip -c > tmp/hadoop.bases.tgz
source ./hadoop/deploy.sh
docker save hadoop:wzh | gzip -c > tmp/hadoop.wzh.tgz

# kafka
source ./kafka/kafka-connect/deploy.sh
docker save cp-kafka-connect:wzh | gzip -c > tmp/cp-kafka-connect.wzh.tgz

# hue
source ./hue/deploy.sh
docker save hue:wzh | gzip -c > tmp/hue.wzh.tgz

# flume
source ./flume/docker/base.sh
docker save flume:build | gzip -c > tmp/flume.build.tgz
source ./flume/deploy.sh
docker save flume:wzh | gzip -c > tmp/flume.wzh.tgz
