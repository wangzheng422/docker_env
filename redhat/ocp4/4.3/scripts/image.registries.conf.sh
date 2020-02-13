#!/usr/bin/env bash

set -e
set -x

parm_file=$1

export LOCAL_REG='registry.redhat.ren:5443'
export MID_REG="registry.redhat.ren"

# export OCP_RELEASE=${BUILDNUMBER}
# export LOCAL_REG='registry.redhat.ren'
# export LOCAL_REPO='ocp4/openshift4'
# export UPSTREAM_REPO='openshift-release-dev'
# export LOCAL_SECRET_JSON="pull-secret.json"
# export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
# export RELEASE_NAME="ocp-release"

# /bin/rm -rf ./operator/yaml/
# mkdir -p ./operator/yaml/
cat << EOF > ./image.registries.conf
unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]

EOF

yaml_docker_image(){

    docker_image=$1
    local_image=$(echo $2 | sed "s/${MID_REG}/${LOCAL_REG}/")
    num=$3
    # echo $docker_image

cat << EOF >> ./image.registries.conf
[[registry]]
  location = "${docker_image}"
  insecure = false
  blocked = false
  mirror-by-digest-only = false
  prefix = ""

  [[registry.mirror]]
    location = "${local_image}"
    insecure = true
EOF

}

declare -i num=1

while read -r line; do

    docker_image=$(echo $line | awk  '{split($0,a,"\t"); print a[1]}')
    local_image=$(echo $line | awk  '{split($0,a,"\t"); print a[2]}')

    echo $docker_image
    echo $local_image

    yaml_docker_image $docker_image $local_image $num
    num=${num}+1;

done < ${parm_file} # yaml.image.ok.list.uniq


cat << EOF >> ./image.registries.conf

[[registry]]
  location = "quay.io/openshift-release-dev/ocp-release"
  insecure = false
  blocked = false
  mirror-by-digest-only = true
  prefix = ""

  [[registry.mirror]]
    location = "${LOCAL_REG}/ocp4/openshift4"
    insecure = true

[[registry]]
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  insecure = false
  blocked = false
  mirror-by-digest-only = true
  prefix = ""

  [[registry.mirror]]
    location = "${LOCAL_REG}/ocp4/openshift4"
    insecure = true

[[registry]]
  location = "${LOCAL_REG}"
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
      version: 2.2.0
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
      version: 2.2.0
    storage:
      files:
      - contents:
          source: data:text/plain,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf
EOF