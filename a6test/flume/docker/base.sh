#!/usr/bin/env bash

set -e
set -x

docker build -t flume:build -f build.Dockerfile ./
