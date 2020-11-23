#!/usr/bin/env bash

set -e
set -x

parm_local_reg=$1

cat << EOF > ./image.registries.conf
unqualified-search-registries = ["registry.redhat.io", "registry.access.redhat.com", "docker.io"]

[[registry]]
  location = ""
  insecure = false
  blocked = false
  mirror-by-digest-only = false
  prefix = ""

  [[registry.mirror]]
    location = "${parm_local_reg}/"
    insecure = true

[[registry]]
  location = "quay.io/openshift-release-dev/ocp-release"
  insecure = false
  blocked = false
  mirror-by-digest-only = true
  prefix = ""

  [[registry.mirror]]
    location = "${parm_local_reg}/ocp4/openshift4"
    insecure = true

[[registry]]
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  insecure = false
  blocked = false
  mirror-by-digest-only = true
  prefix = ""

  [[registry.mirror]]
    location = "${parm_local_reg}/ocp4/openshift4"
    insecure = true

[[registry]]
  location = "${parm_local_reg}"
  insecure = true
  blocked = false
  mirror-by-digest-only = false
  prefix = ""

EOF

config_source=$(cat ./image.registries.conf | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(''.join(sys.stdin.readlines())))"  )

cat <<EOF > 99-worker-zzz-container-registries.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-zzz-container-registries
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          source: data:text/plain,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf
EOF

cat <<EOF > 99-master-zzz-container-registries.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-zzz-container-registries
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          source: data:text/plain,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf
EOF