#!/usr/bin/env bash

set -e
set -x

# source config.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t cdh:wzh ${DIR}/