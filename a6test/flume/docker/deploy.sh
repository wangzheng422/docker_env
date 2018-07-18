#!/usr/bin/env bash

set -e
set -x

docker build -t flume:build -f build.base.Dockerfile ./
docker build -t flume:wzh -f build.Dockerfile ./