#!/usr/bin/env bash

set -e
set -x

docker-compose up -d -V

docker run --rm --network es_ai_esnet -it es_ai:wzh bash
