#!/usr/bin/env bash

set -e
set -x

PWD=$(pwd)

docker build -t elasticsearch:wzh ${PWD}/