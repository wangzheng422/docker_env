#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp

files=(
    elasticsearch.wzh.tgz
    centos.wzh.tgz
    hadoop.bases.tgz
    hadoop.wzh.tgz
    cp-kafka-connect.wzh.tgz
    hue.wzh.tgz
    flume.build.tgz
    flume.wzh.tgz
    kite.build.tgz
    dbz.wzh.tgz
    kudu.wzh.tgz
)

for i in "${files[@]}"; do
    zcat tmp/$i | docker load
done

# zcat tmp/elasticsearch.wzh.tgz | docker load
# zcat tmp/centos.wzh.tgz | docker load
# zcat tmp/hadoop.bases.tgz | docker load
# zcat tmp/hadoop.wzh.tgz | docker load
# zcat tmp/cp-kafka-connect.wzh.tgz | docker load
# zcat tmp/hue.wzh.tgz | docker load
# zcat tmp/flume.build.tgz | docker load
# zcat tmp/flume.wzh.tgz | docker load
# zcat tmp/kite.build.tgz | docker load
# zcat tmp/dbz.wzh.tgz | docker load
# zcat tmp/kudu.wzh.tgz | docker load

