#!/usr/bin/env bash

set -e
set -x

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

docker build -t flume:build -f ${SCRIPTPATH}/build.Dockerfile ${SCRIPTPATH}/
