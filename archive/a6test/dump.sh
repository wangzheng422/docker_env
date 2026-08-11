#!/usr/bin/env bash

set -e
set -x

dummy=$1

mkdir -p tmp

source config.sh

while read -r line; do
    read -ra images <<<"$line"
    echo "docker save ${images[0]} | gzip -c > tmp/${images[1]}"
    if [ "$dummy" != "dummy" ]; then
        docker save ${images[0]} | gzip -c > tmp/${images[1]}
    fi
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

