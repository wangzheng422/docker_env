#!/usr/bin/env bash

set -e
set -x

# source config.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

git pull

docker build -f Dockerfile -t pg:wzh ${DIR}/

docker image prune -f
