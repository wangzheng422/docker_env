#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

pull_docker_image(){
    docker_images=$1
    save_file=$2
    list_file=$3

    echo > $list_file

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then
            if [[ -z $(docker images -q $line) ]]; then
                if docker pull $line; then
                    echo $line >> $list_file
                else
                    echo "# $line">> $list_file
                fi
            else
                echo $line >> $list_file
            fi
        else
            echo $line >> $list_file
        fi

        if [ ! -z "$sleep_time" ]; then
            sleep $sleep_time
        fi
    done <<< "$docker_images"

}

#################################
## pull and dump images

pull_docker_image "$ose3_images" "ose3-images.tgz" "ose3-images.list"

pull_docker_image "$ose3_optional_imags" "ose3-optional-imags.tgz" "ose3-optional-imags.list"

pull_docker_image "$ose3_builder_images" "ose3-builder-images.tgz" "ose3-builder-images.list"

pull_docker_image "$cnv_optional_imags" "cnv-optional-images.tgz" "cnv-optional-images.list"

pull_docker_image "$istio_optional_imags" "istio-optional-images.tgz" "istio-optional-images.list"

pull_docker_image "$docker_builder_images" "docker-builder-images.tgz" "docker-builder-images.list"

pull_docker_image "$quay_builder_images" "quay-builder-images.tgz" "quay-builder-images.list"

pull_docker_image "$gcr_builder_images" "gcr-builder-images.tgz" "gcr-builder-images.list"

##################################

docker image prune -f



