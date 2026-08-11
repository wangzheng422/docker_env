#!/usr/bin/env bash

set -e
set -x

mkdir -p tmp

docker save elasticsearch:es_ai_a6 | gzip -c > tmp/elasticsearch.es_ai_a6.tgz
docker save elasticsearch:es_ai | gzip -c > tmp/elasticsearch.es_ai.tgz
docker save es_ai:wzh | gzip -c > tmp/es_ai.wzh.tgz
docker save docker.elastic.co/kibana/kibana-oss:6.3.1 | gzip -c > tmp/kibana-oss.6.3.1.tgz
docker save elastichq/elasticsearch-hq | gzip -c > tmp/elasticsearch-hq.wzh.tgz

docker image prune -f