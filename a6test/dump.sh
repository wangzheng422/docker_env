#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

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

while read -r line; do
    read -ra images <<<"$line"
    echo "docker save ${images[0]} | gzip -c > tmp/${images[1]}"
done <<< "$VAR"

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

