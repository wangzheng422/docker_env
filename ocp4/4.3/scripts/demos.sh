#!/usr/bin/env bash

set -e
set -x

mkdir -p /data/ocp4/demo/

cd /data/ocp4/demo

git clone https://github.com/openshift-psap/gpu-burn.git

git clone https://github.com/redhat-developer/redhat-helm-charts

git clone https://github.com/redhat-gpte-devopsautomation/openshift-tasks.git



