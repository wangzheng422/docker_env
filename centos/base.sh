#!/usr/bin/env bash

set -e
set -x

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

docker build -f ${SCRIPTPATH}/base.Dockerfile -t centos:wzh ${SCRIPTPATH}/

