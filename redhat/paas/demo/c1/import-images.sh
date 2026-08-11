#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

import_docker_image(){
    docker_images=$1
    save_file=$2
    list_file=$3

    docker load -i $save_file
}

#################################
## pull and dump images

import_docker_image "$ose3_images" "ose3-images.tgz" "ose3-images.list"

import_docker_image "$ose3_optional_imags" "ose3-optional-imags.tgz" "ose3-optional-imags.list"

import_docker_image "$ose3_builder_images" "ose3-builder-images.tgz" "ose3-builder-images.list"

import_docker_image "$cnv_optional_imags" "cnv-optional-images.tgz" "cnv-optional-images.list"

import_docker_image "$istio_optional_imags" "istio-optional-images.tgz" "istio-optional-images.list"

import_docker_image "$docker_builder_images" "docker-builder-images.tgz" "docker-builder-images.list"

import_docker_image "$quay_builder_images" "quay-builder-images.tgz" "quay-builder-images.list"

##################################

docker image prune -f



