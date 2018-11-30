#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp

source config.sh

# for i in "${files[@]}"; do
#     zcat tmp/$i | docker load
# done

while read -r line; do
    read -ra images <<<"$line"
    echo "zcat ${images[1]} | docker load"
    zcat tmp/${images[1]} | docker load
done <<< "$VAR"

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

