#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp
export REGISTRY=11.11.157.144:5000
export DIR=./
# source config.sh

zcat ${DIR}/elasticsearch.wzh.tgz | docker load
docker tag elasticsearch:wzh ${REGISTRY}/elasticsearch:wzh
docker push ${REGISTRY}/elasticsearch:wzh

# docker save filebeat:wzh | gzip -c > ${DIR}/filebeat.wzh.tgz
zcat ${DIR}/filebeat.wzh.tgz | docker load
docker tag filebeat:wzh ${REGISTRY}/filebeat:wzh
docker push ${REGISTRY}/filebeat:wzh

# docker save centos:wzh | gzip -c > ${DIR}/centos.wzh.tgz
zcat ${DIR}/centos.wzh.tgz | docker load
docker tag centos:wzh ${REGISTRY}/centos:wzh
docker push ${REGISTRY}/centos:wzh

# docker save hadoop:base | gzip -c > ${DIR}/hadoop.bases.tgz
zcat ${DIR}/hadoop.base.tgz | docker load
docker tag hadoop:base ${REGISTRY}/hadoop:base
docker push ${REGISTRY}/hadoop:base

# docker save hadoop:wzh | gzip -c > ${DIR}/hadoop.wzh.tgz
zcat ${DIR}/hadoop.wzh.tgz | docker load
docker tag hadoop:wzh ${REGISTRY}/hadoop:wzh
docker push ${REGISTRY}/hadoop:wzh

# docker save cp-kafka-connect:wzh | gzip -c > ${DIR}/cp-kafka-connect.wzh.tgz
zcat ${DIR}/cp-kafka-connect.wzh.tgz | docker load
docker tag cp-kafka-connect:wzh ${REGISTRY}/cp-kafka-connect:wzh
docker push ${REGISTRY}/cp-kafka-connect:wzh

# docker save hue:wzh | gzip -c > ${DIR}/hue.wzh.tgz
zcat ${DIR}/hue.wzh.tgz | docker load
docker tag hue:wzh ${REGISTRY}/hue:wzh
docker push ${REGISTRY}/hue:wzh

# docker save flume:build | gzip -c > ${DIR}/flume.build.tgz
zcat ${DIR}/flume.build.tgz | docker load
docker tag flume:build ${REGISTRY}/flume:build
docker push ${REGISTRY}/flume:build

# docker save flume:wzh | gzip -c > ${DIR}/flume.wzh.tgz
zcat ${DIR}/flume.wzh.tgz | docker load
docker tag flume:wzh ${REGISTRY}/flume:wzh
docker push ${REGISTRY}/flume:wzh

# docker save kite:build | gzip -c > ${DIR}/kite.build.tgz
zcat ${DIR}/kite.build.tgz | docker load
docker tag kite:build ${REGISTRY}/kite:build
docker push ${REGISTRY}/kite:build

# docker save mysql:5.7 | gzip -c > ${DIR}/mysql.5.7.tgz
zcat ${DIR}/mysql.5.7.tgz | docker load
docker tag mysql:5.7 ${REGISTRY}/mysql:5.7
docker push ${REGISTRY}/mysql:5.7

docker image prune -f

# zcat elasticsearch.es_ai_a6.tgz | docker load
# docker tag elasticsearch:es_ai_a6 ${REGISTRY}/elasticsearch:es_ai_a6
# docker push ${REGISTRY}/elasticsearch:es_ai_a6

# zcat es_ai.wzh.tgz | docker load
# docker tag es_ai:wzh ${REGISTRY}/es_ai:wzh
# docker push ${REGISTRY}/es_ai:wzh

# zcat kibana-oss.6.3.1.tgz | docker load
# docker tag docker.elastic.co/kibana/kibana-oss:6.3.1 ${REGISTRY}/kibana-oss:6.3.1
# docker push ${REGISTRY}/kibana-oss:6.3.1

# zcat elasticsearch-hq.wzh.tgz | docker load
# docker tag elastichq/elasticsearch-hq ${REGISTRY}/elasticsearch-hq:wzh
# docker push ${REGISTRY}/elasticsearch-hq:wzh


