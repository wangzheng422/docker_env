#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp

files=(
    elasticsearch.wzh.tgz
    filebeat.wzh.tgz
    centos.wzh.tgz
    hadoop.bases.tgz
    hadoop.wzh.tgz
    cp-kafka-connect.wzh.tgz
    hue.wzh.tgz
    flume.build.tgz
    flume.wzh.tgz
    kite.build.tgz
    mysql.5.7.tgz
    kudu.wzh.tgz
    teiid.wzh.tgz
    adminer.tgz
    kibana.tgz
    elasticsearch-hq.tgz
    zookeeper.3.4.12.tgz
    cp-kafka.4.1.1.tgz
    cp-schema-registry.4.1.1.tgz
    schema-registry-ui.0.9.4.tgz
    cp-kafka-rest.4.1.1.tgz
    kafka-topics-ui.0.9.3.tgz
    kafka-connect-ui.0.9.4.tgz
    zoonavigator-web.0.5.0.tgz
    zoonavigator-api.0.5.0.tgz
    oracle-11g.wzh.11.2.0.4.tgz
    dbz-oracle.wzh.tgz
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

