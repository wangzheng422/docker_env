#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

#################################
## pull and dump images

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$ose3_images"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_images"

$($cmd_str | gzip -c > ose3-images.tgz)

###################################
## pull and dump images

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$ose3_optional_imags"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_optional_imags"

$($cmd_str | gzip -c > ose3-optional-imags.tgz)

####################################
## pull and dump images

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$ose3_builder_images"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$ose3_builder_images"

$($cmd_str | gzip -c > ose3-builder-images.tgz)

##################################
## pull and dump images

while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        docker pull $line;
    fi
done <<< "$other_builder_images"

cmd_str="docker save "
while read -r line; do
    if [[ "$line" =~ [^[:space:]] ]]; then
        cmd_str+=" $line"
    fi
done <<< "$other_builder_images"

$($cmd_str | gzip -c > other-builder-images.tgz)

##################################

docker image prune -f



