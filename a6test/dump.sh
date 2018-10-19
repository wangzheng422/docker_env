#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

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
done

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
# docker save dbz:wzh | gzip -c > tmp/dbz.wzh.tgz
# docker save kudu:wzh | gzip -c > tmp/kudu.wzh.tgz
# docker save teiid:wzh | gzip -c > tmp/teiid.wzh.tgz
# docker save adminer | gzip -c > tmp/adminer.tgz

# docker save docker.elastic.co/kibana/kibana-oss:6.3.1 | gzip -c > tmp/kibana.tgz
# docker save elastichq/elasticsearch-hq | gzip -c > tmp/elasticsearch-hq.tgz

docker image prune -f