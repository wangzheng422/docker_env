#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

pull_and_save_docker_image(){
    $docker_images = $1
    $save_file = $2

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]]; then
            docker pull $line;
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

pull_and_save_docker_image $ose3_images "ose3-images.tgz"

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$ose3_images"

# cmd_str="docker save "
# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         cmd_str+=" $line"
#     fi
# done <<< "$ose3_images"

# $($cmd_str | gzip -c > ose3-images.tgz)

###################################
## pull and dump images

pull_and_save_docker_image $ose3_optional_imags "ose3-optional-imags.tgz"

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$ose3_optional_imags"

# cmd_str="docker save "
# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         cmd_str+=" $line"
#     fi
# done <<< "$ose3_optional_imags"

# $($cmd_str | gzip -c > ose3-optional-imags.tgz)

####################################
## pull and dump images

pull_and_save_docker_image $ose3_builder_images "ose3-builder-images.tgz"

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$ose3_builder_images"

# cmd_str="docker save "
# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         cmd_str+=" $line"
#     fi
# done <<< "$ose3_builder_images"

# $($cmd_str | gzip -c > ose3-builder-images.tgz)

##################################
## pull and dump images

pull_and_save_docker_image $docker_builder_images "docker-builder-images.tgz"

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$docker_builder_images"

# cmd_str="docker save "
# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         cmd_str+=" $line"
#     fi
# done <<< "$docker_builder_images"

# $($cmd_str | gzip -c > docker-builder-images.tgz)

##################################
## pull and dump images

pull_and_save_docker_image $other_builder_images "other-builder-images.tgz"

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$other_builder_images"

# cmd_str="docker save "
# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         cmd_str+=" $line"
#     fi
# done <<< "$other_builder_images"

# $($cmd_str | gzip -c > other-builder-images.tgz)

##################################




docker image prune -f



