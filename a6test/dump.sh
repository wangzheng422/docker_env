#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

docker save elasticsearch:wzh | gzip -c > tmp/elasticsearch.wzh.tgz
docker save filebeat:wzh | gzip -c > tmp/filebeat.wzh.tgz
docker save centos:wzh | gzip -c > tmp/centos.wzh.tgz
docker save hadoop:base | gzip -c > tmp/hadoop.base.tgz
docker save hadoop:wzh | gzip -c > tmp/hadoop.wzh.tgz
docker save cp-kafka-connect:wzh | gzip -c > tmp/cp-kafka-connect.wzh.tgz
docker save hue:wzh | gzip -c > tmp/hue.wzh.tgz
docker save flume:build | gzip -c > tmp/flume.build.tgz
docker save flume:wzh | gzip -c > tmp/flume.wzh.tgz
docker save kite:build | gzip -c > tmp/kite.build.tgz
docker save mysql:5.7 | gzip -c > tmp/mysql.5.7.tgz

docker image prune -f