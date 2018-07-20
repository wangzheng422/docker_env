#!/usr/bin/env bash

set -e
set -x

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -f ${DIR}/base.Dockerfile -t ubuntu:base ${DIR}/

# docker save hadoop:base | gzip -c > tmp/hadoop.base.tgz

# docker pull mysql:5.7
# docker save mysql:5.7 | gzip -c > tmp/mysql.5.7.tgz
