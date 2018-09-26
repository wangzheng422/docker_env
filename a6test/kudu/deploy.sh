#!/usr/bin/env bash

set -e
set -x

# source config.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cp -f ${DIR}/../flume/docker/schema/* ${DIR}/schema


docker build -t kudu:wzh ${DIR}/