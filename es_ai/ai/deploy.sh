#!/usr/bin/env bash

set -e
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")

docker build -t es_ai:wzh ${DIR}/