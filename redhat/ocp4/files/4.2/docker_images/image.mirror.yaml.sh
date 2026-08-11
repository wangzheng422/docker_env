#!/usr/bin/env bash

set -e
set -x

# export OCP_RELEASE=${BUILDNUMBER}
# export LOCAL_REG='registry.redhat.ren'
# export LOCAL_REPO='ocp4/openshift4'
# export UPSTREAM_REPO='openshift-release-dev'
# export LOCAL_SECRET_JSON="pull-secret.json"
# export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
# export RELEASE_NAME="ocp-release"

# /bin/rm -rf ./operator/yaml/
# mkdir -p ./operator/yaml/
cat << EOF > ./image.mirror.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: mirror-images
spec:
  repositoryDigestMirrors:
EOF

yaml_docker_image(){

    docker_image=$1
    local_image=$2
    num=$3
    # echo $docker_image

cat << EOF >> ./image.mirror.yaml
  - mirrors:
    - ${local_image}
    source: ${docker_image}
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

done < yaml.image.ok.list.uniq
