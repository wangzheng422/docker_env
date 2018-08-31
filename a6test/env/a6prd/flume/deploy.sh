#!/usr/bin/env bash

set -e
set -x

# source config.sh

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")
export REGISTRY=11.11.157.191:5000/a6-pro

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t ${REGISTRY}/flume:a6 ${DIR}/




