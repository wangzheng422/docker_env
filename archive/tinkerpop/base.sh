#!/usr/bin/env bash

set -e
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -f ${DIR}/base.Dockerfile -t tinkerpop:wzh ${DIR}/

