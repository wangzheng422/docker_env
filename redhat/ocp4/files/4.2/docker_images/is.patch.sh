#!/usr/bin/env bash

set -e
set -x

export LOCAL_REG='registry.redhat.ren'

oc get is -n openshift -l samples.operator.openshift.io/managed=true

oc get is jenkins-agent-maven -n openshift -o=jsonpath='{.spec.tags[*].from.name}'


