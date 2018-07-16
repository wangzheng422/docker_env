#!/usr/bin/env bash

set -e
set -x

docker build -f ./base.Dockerfile -t centos:wzh ./

