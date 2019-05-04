#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

remove_docker_image(){
    docker_images=$1
    split_tag=$2
    list_file=$3

    cmd_img_str=" "

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then
            # part1=$(echo $line | awk  '{split($0,a,$split_tag); print a[2]}')
            part1=${line#*${split_tag}}
            part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
            part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
            if [[ "$part3" =~ [^[:space:]] ]]; then
                cmd_img_str+=" $private_repo$part2:$part3"
                cmd_img_str+=" $private_repo$part2:$major_tag"
                cmd_img_str+=" $private_repo$part2:$tag"
                cmd_img_str+=" $private_repo$part2"
            else
                cmd_img_str+=" $private_repo$part2"
                cmd_img_str+=" $private_repo$part2:$major_tag"
                cmd_img_str+=" $private_repo$part2:$tag"
            fi
            cmd_img_str+=" $line";
        fi
    done < $list_file

    docker image rm -f $cmd_img_str
}

#################################
## pull and dump images

remove_docker_image "$ose3_images" "redhat.io"  "ose3-images.list"

remove_docker_image "$ose3_optional_imags" "redhat.io"  "ose3-optional-imags.list"

remove_docker_image "$ose3_builder_images" "redhat.io"  "ose3-builder-images.list"

remove_docker_image "$cnv_optional_imags" "redhat.io"  "cnv-optional-images.list"

remove_docker_image "$istio_optional_imags" "redhat.io"  "istio-optional-images.list"

# remove_docker_image "$docker_builder_images" "docker-builder-images.list"

remove_docker_image "$other_builder_images" "quay.io" "other-builder-images.list"

##################################

docker image prune -f



