#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

remove_docker_image(){
    docker_images=$1

    cmd_img_str=" "

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]]; then
            cmd_img_str+=" $line";
        fi
    done <<< "$docker_images"

    docker image rm -f $cmd_img_str
}

#################################
## pull and dump images

remove_docker_image "$ose3_images"

remove_docker_image "$ose3_optional_imags"

remove_docker_image "$ose3_builder_images"

remove_docker_image "$cnv_optional_imags"

remove_docker_image "$istio_optional_imags"

remove_docker_image "$docker_builder_images"

remove_docker_image "$other_builder_images"

##################################

docker image prune -f



