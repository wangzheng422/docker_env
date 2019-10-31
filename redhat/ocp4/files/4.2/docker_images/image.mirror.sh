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

cat << EOF > mirror-image.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: operator-images
spec:
  repositoryDigestMirrors:
EOF

mirror_docker_image(){

    docker_image=$1
    echo $docker_image

    if [[ "$docker_image" =~ ^$ ]] || [[ "$docker_image" =~ ^[[:space:]]+$ ]] || [[ "$docker_image" =~ \#[:print:]*  ]]; then
        # echo "this is comments"
        return;
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*:.* ]]; then
        # echo "io, com, org with tag: $docker_image"
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io\|com\|org)//')
        image_url="${LOCAL_REG}${image_part}"
        # echo $image_url
    elif [[ $docker_image =~ ^.*\.(io|com|org)/[^:]*  ]]; then
        # echo "io, com, org without tag: $docker_image"
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io\|com\|org)//')
        image_url="${LOCAL_REG}${image_part}:latest"
        # echo $image_url
        docker_image+=":latest"
    elif [[ $docker_image =~ ^.*/.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        image_url="${LOCAL_REG}/${docker_image}"
        # echo $image_url
    elif [[ $docker_image =~ ^.*/[^:]* ]]; then
        # echo "docker without tag: $docker_image"
        image_url="${LOCAL_REG}/${docker_image}:latest"
        # echo $image_url
        docker_image+=":latest"
    fi

    oc image mirror $docker_image $image_url

cat << EOF >> mirror-image.yaml
    - ${image_url}
    source: ${docker_image}
EOF
}

while read -r line; do

    mirror_docker_image $line

done < install.image.list

while read -r line; do

    delimiter="\t"
    declare -a array=($(echo $line | tr "$delimiter" " "))
    url=${array[0]}

    mirror_docker_image $url

done < operator.image.list



