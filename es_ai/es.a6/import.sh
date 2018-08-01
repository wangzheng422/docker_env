#!/usr/bin/env bash

set -e
set -x

# mkdir -p tmp
export REGISTRY=11.11.157.144:5000

zcat elasticsearch.es_ai_a6.tgz | docker load
docker tag elasticsearch:es_ai_a6 ${REGISTRY}/elasticsearch:es_ai_a6
docker push ${REGISTRY}/elasticsearch:es_ai_a6

zcat elasticsearch.es_ai.tgz | docker load
docker tag elasticsearch:es_ai ${REGISTRY}/elasticsearch:es_ai
docker push ${REGISTRY}/elasticsearch:es_ai

zcat es_ai.wzh.tgz | docker load
docker tag es_ai:wzh ${REGISTRY}/es_ai:wzh
docker push ${REGISTRY}/es_ai:wzh

zcat kibana-oss.6.3.1.tgz | docker load
docker tag docker.elastic.co/kibana/kibana-oss:6.3.1 ${REGISTRY}/kibana-oss:6.3.1
docker push ${REGISTRY}/kibana-oss:6.3.1

zcat elasticsearch-hq.latest.tgz | docker load
docker tag elastichq/elasticsearch-hq ${REGISTRY}/elasticsearch-hq:wzh
docker push ${REGISTRY}/elasticsearch-hq:wzh


