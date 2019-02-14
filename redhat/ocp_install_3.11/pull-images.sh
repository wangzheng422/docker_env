#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

source config.sh

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$ose3_images"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_images"

$($cmd_str | gzip -c > ose3-images.tgz)

###################################

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$ose3_optional_imags"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_optional_imags"

$($cmd_str | gzip -c > ose3-optional-imags.tgz)

####################################

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         docker pull $line;
#     fi
# done <<< "$ose3_builder_images"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_builder_images"

$($cmd_str | gzip -c > ose3-builder-images.tgz)

##################################3

docker image prune -f



