#!/usr/bin/env bash

set -e
set -x

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -f 12.2.Dockerfile -t dbz-oracle-12-2:wzh ${DIR}/
docker build -f 11.2.Dockerfile -t dbz-oracle-11-2:wzh ${DIR}/
docker build -t dbz-oracle:wzh ${DIR}/