#!/usr/bin/env bash

set -e
set -x

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t flume:build -f ${DIR}/build.Dockerfile ${DIR}/

docker build -t kite:build -f ${DIR}/kite.Dockerfile ${DIR}/
