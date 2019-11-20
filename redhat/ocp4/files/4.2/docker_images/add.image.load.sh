#!/usr/bin/env bash

set -e
set -x

source image.mirror.fn.sh

while read -r line; do

    delimiter="\t"
    declare -a array=($(echo $line | tr "$delimiter" " "))
    docker_image=${array[0]}
    tar_file_name=${array[1]}
    local_image_url=${array[2]}

    skopeo copy "docker-archive:./image_tar/"$tar_file_name "docker://"$local_image_url

done < pull.add.image.ok.list



