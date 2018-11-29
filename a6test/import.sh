#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp

VAR=$(cat << EOF
elasticsearch:wzh elasticsearch.wzh.tgz
filebeat:wzh filebeat.wzh.tgz
centos:wzh centos.wzh.tgz
hadoop:base hadoop.bases.tgz
hadoop:wzh hadoop.wzh.tgz
cp-kafka-connect:wzh cp-kafka-connect.wzh.tgz
hue:wzh hue.wzh.tgz 
flume:build flume.build.tgz
flume:wzh flume.wzh.tgz
kite:build kite.build.tgz
mysql:5.7 mysql.5.7.tgz
kudu:wzh kudu.wzh.tgz
teiid:wzh teiid.wzh.tgz
adminer adminer.tgz
docker.elastic.co/kibana/kibana-oss:6.3.1 kibana.tgz
elastichq/elasticsearch-hq elasticsearch-hq.tgz
zookeeper:3.4.12 zookeeper.3.4.12.tgz
confluentinc/cp-kafka:4.1.1-2 cp-kafka.4.1.1.tgz
confluentinc/cp-schema-registry:4.1.1-2 cp-schema-registry.4.1.1.tgz
landoop/schema-registry-ui:0.9.4 schema-registry-ui.0.9.4.tgz
confluentinc/cp-kafka-rest:4.1.1-2 cp-kafka-rest.4.1.1.tgz
landoop/kafka-topics-ui:0.9.3 kafka-topics-ui.0.9.3.tgz
landoop/kafka-connect-ui:0.9.4 kafka-connect-ui.0.9.4.tgz
elkozmon/zoonavigator-web:0.5.0 zoonavigator-web.0.5.0.tgz
elkozmon/zoonavigator-api:0.5.0 zoonavigator-api.0.5.0.tgz
oracle-11g:wzh.11.2.0.4 oracle-11g.wzh.11.2.0.4.tgz
dbz-oracle:wzh dbz-oracle.wzh.tgz
EOF
)

# for i in "${files[@]}"; do
#     zcat tmp/$i | docker load
# done

while read -r line; do
    read -ra images <<<"$line"
    echo "zcat ${images[1]} | docker load"
    zcat ${images[1]} | docker load
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

