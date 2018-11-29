#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

images=(
    (elasticsearch:wzh elasticsearch.wzh.tgz)
    (filebeat:wzh filebeat.wzh.tgz)
    
)

files=(
    elasticsearch.wzh.tgz
    filebeat.wzh.tgz
 
)

read -r -d '' VAR << EOF
elasticsearch:wzh elasticsearch.wzh.tgz
filebeat:wzh filebeat.wzh.tgz
EOF

for i in "$VAR"; do
    echo "docker save ${i[0]} | gzip -c > tmp/${i[1]}"
    # docker save ${images[$i][0]} | gzip -c > tmp/${files[$i][1]}
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

