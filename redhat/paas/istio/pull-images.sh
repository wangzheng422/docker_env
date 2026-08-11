#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

pull_and_save_docker_image(){
    docker_images=$1
    save_file=$2
    sleep_time=$3

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]]; then
            # [ ! -z $(docker images -q $line) ] || docker pull $line;
            docker pull $line
        fi

        if [ ! -z "$sleep_time" ]; then
            sleep $sleep_time
        fi
    done <<< "$docker_images"

    cmd_str="docker save "
    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]]; then
            cmd_str+=" $line"
        fi
    done <<< "$docker_images"

    $cmd_str | gzip -c > $save_file
}

#################################
## pull and dump images

# pull_and_save_docker_image "$ose3_images" "ose3-images.tgz"

# pull_and_save_docker_image "$ose3_optional_imags" "ose3-optional-imags.tgz"

# pull_and_save_docker_image "$ose3_builder_images" "ose3-builder-images.tgz"

# pull_and_save_docker_image "$cnv_optional_imags" "cnv-optional-images.tgz"

pull_and_save_docker_image "$istio_optional_imags" "istio-optional-images.tgz"

# pull_and_save_docker_image "$docker_builder_images" "docker-builder-images.tgz"

# pull_and_save_docker_image "$other_builder_images" "other-builder-images.tgz"

##################################

docker image prune -f



