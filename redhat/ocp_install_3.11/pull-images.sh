#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

source config.sh

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$ose3_images"

cmd_str="docker save -o ose3-images.tar "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_images"

$($cmd_str)

###################################

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$ose3_optional_imags"

cmd_str="docker save -o ose3-optional-imags.tar "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_optional_imags"

$($cmd_str)

####################################

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$ose3_builder_images"

cmd_str="docker save -o ose3-builder-images.tar "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_builder_images"

$($cmd_str)

##################################3

docker image prune -f



