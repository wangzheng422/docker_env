#!/usr/bin/env bash

set -e
set -x

docker-compose up -d -V

# docker exec -it filebeat
# docker-compose exec filebeat bash
# ./filebeat setup --dashboards