#!/usr/bin/env bash

set -e
set -x

docker build -f ./base.Dockerfile -t hadoop:base ./

# docker save hadoop:base | gzip -c > tmp/hadoop.base.tgz

# docker pull mysql:5.7
# docker save mysql:5.7 | gzip -c > tmp/mysql.5.7.tgz
