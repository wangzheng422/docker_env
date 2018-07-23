#!/usr/bin/env bash

set -e
set -x

docker-compose down -v

docker volume prune -f

# docker exec -it filebeat
# ./filebeat setup --dashboards