#!/usr/bin/env bash

set -e
set -x

docker-compose up -d -V

docker run --rm -it es_ai:wzh bash
