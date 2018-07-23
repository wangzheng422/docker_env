#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp

zcat tmp/elasticsearch.wzh.tgz | docker load
zcat tmp/centos.wzh.tgz | docker load
zcat tmp/hadoop.bases.tgz | docker load
zcat tmp/hadoop.wzh.tgz | docker load
zcat tmp/cp-kafka-connect.wzh.tgz | docker load
zcat tmp/hue.wzh.tgz | docker load
zcat tmp/flume.build.tgz | docker load
zcat tmp/flume.wzh.tgz | docker load
zcat tmp/kite.build.tgz | docker load
