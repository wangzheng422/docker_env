#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

images=(
    elasticsearch:wzh
    filebeat:wzh
    centos:wzh
    hadoop:base
    hadoop:wzh
    cp-kafka-connect:wzh
    hue:wzh
    flume:build
    flume:wzh
    kite:build
    mysql:5.7
    kudu:wzh
    teiid:wzh
    adminer
    docker.elastic.co/kibana/kibana-oss:6.3.1
    elastichq/elasticsearch-hq
    zookeeper:3.4.12
    confluentinc/cp-kafka:4.1.1-2
    confluentinc/cp-schema-registry:4.1.1-2
    landoop/schema-registry-ui:0.9.4
    confluentinc/cp-kafka-rest:4.1.1-2
    landoop/kafka-topics-ui:0.9.3
    landoop/kafka-connect-ui:0.9.4
    elkozmon/zoonavigator-web:0.5.0
    elkozmon/zoonavigator-api:0.5.0
    oracle-11g:wzh.11.2.0.4
    dbz-oracle:wzh
)

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

for i in "${!images[@]}"; do
    echo "docker save ${images[$i]} | gzip -c > tmp/${files[$i]}"
    docker save ${images[$i]} | gzip -c > tmp/${files[$i]}
done

docker image prune -f

# docker save elasticsearch:wzh | gzip -c > tmp/elasticsearch.wzh.tgz
# docker save filebeat:wzh | gzip -c > tmp/filebeat.wzh.tgz
# docker save centos:wzh | gzip -c > tmp/centos.wzh.tgz
# docker save hadoop:base | gzip -c > tmp/hadoop.base.tgz
# docker save hadoop:wzh | gzip -c > tmp/hadoop.wzh.tgz
# docker save cp-kafka-connect:wzh | gzip -c > tmp/cp-kafka-connect.wzh.tgz
# docker save hue:wzh | gzip -c > tmp/hue.wzh.tgz
# docker save flume:build | gzip -c > tmp/flume.build.tgz
# docker save flume:wzh | gzip -c > tmp/flume.wzh.tgz
# docker save kite:build | gzip -c > tmp/kite.build.tgz
# docker save mysql:5.7 | gzip -c > tmp/mysql.5.7.tgz
# docker save dbz-oracle:wzh | gzip -c > tmp/dbz-oracle.wzh.tgz
# docker save kudu:wzh | gzip -c > tmp/kudu.wzh.tgz
# docker save teiid:wzh | gzip -c > tmp/teiid.wzh.tgz
# docker save adminer | gzip -c > tmp/adminer.tgz
# docker save oracle-11g:wzh.11.2.0.4 | gzip -c > tmp/oracle-11g.wzh.11.2.0.4.tgz

# docker save docker.elastic.co/kibana/kibana-oss:6.3.1 | gzip -c > tmp/kibana.tgz
# docker save elastichq/elasticsearch-hq | gzip -c > tmp/elasticsearch-hq.tgz

