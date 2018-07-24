#!/usr/bin/env bash

set -e
set -x

# source config.sh

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cp -f ${DIR}/../flume/docker/schema/* ${DIR}/schema

# cat k8s.yml | \
# sed "s/{{ALB_IP}}/${ALB_IP}/g" | \
# sed "s/{{GIT_HOST}}/${GIT_HOST}/g" | \
# sed "s/{{REGISTRY}}/${REGISTRY}/g" | \
# sed "s/{{REGION}}/${REGION}/g" | \
# sed "s/{{NGINX}}/${NGINX}/g" | \
# sed "s/{{NODE_IPS}}/${NODE_IPS}/g" | \
# sed "s/{{NAME_NODE_ADDR}}/${NAME_NODE_ADDR}/g"  \
# > k8s-tmp.yml

# echo "use k8s-tmp.yaml to deploy the app"

docker build -t hadoop:wzh ${DIR}/
# docker push ${REGISTRY}/hadoop

# docker pull mysql:5.7
# docker tag mysql:5.7 ${REGISTRY}/mysql:5.7
# docker push ${REGISTRY}/mysql:5.7

# docker save ${REGISTRY}/hadoop | gzip -c > tmp/hadoop.tgz
# docker save ${REGISTRY}/mysql:5.7 | gzip -c > tmp/mysql.5.7.tgz



