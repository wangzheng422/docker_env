#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp

declare -A images=(
    [elasticsearch:wzh]=elasticsearch.wzh.tgz
    [filebeat:wzh]=filebeat.wzh.tgz
    [centos:wzh]=centos.wzh.tgz
    [hadoop:base]=hadoop.base.tgz
    [hadoop:wzh]=hadoop.wzh.tgz
    [cp-kafka-connect:wzh]=cp-kafka-connect.wzh.tgz
    [hue:wzh]=hue.wzh.tgz
    [flume:build]=flume.build.tgz
    [flume:wzh]=flume.wzh.tgz
    [kite:build]=kite.build.tgz
    [mysql:5.7]=mysql.5.7.tgz
    [dbz:wzh]=dbz.wzh.tgz
    [kudu:wzh]=kudu.wzh.tgz
    [teiid:wzh]=teiid.wzh.tgz
    [adminer]=adminer.tgz
    [docker.elastic.co/kibana/kibana-oss:6.3.1]=kibana.tgz
    [elastichq/elasticsearch-hq]=elasticsearch-hq.tgz
)

for image in "${!images[@]}"; do
  docker save $image | gzip -c > tmp/${size[$image]}
  zcat tmp/${size[$image]} | docker load
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

# files=(
#     elasticsearch.wzh.tgz
#     centos.wzh.tgz
#     hadoop.bases.tgz
#     hadoop.wzh.tgz
#     cp-kafka-connect.wzh.tgz
#     hue.wzh.tgz
#     flume.build.tgz
#     flume.wzh.tgz
#     kite.build.tgz
#     dbz.wzh.tgz
#     kudu.wzh.tgz
# )

# for i in "${files[@]}"; do
#     zcat tmp/$i | docker load
# done