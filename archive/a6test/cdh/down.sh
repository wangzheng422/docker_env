#!/usr/bin/env bash

set -e
set -x

docker-compose down -v

docker volume prune -f

docker image prune -f
