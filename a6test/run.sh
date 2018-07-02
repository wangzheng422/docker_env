#!/usr/bin/env bash

set -e
set -x

docker-compose up -d

docker run filebeat:wzh setup --dashboards