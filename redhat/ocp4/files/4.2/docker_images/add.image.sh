#!/usr/bin/env bash

set -e
set -x

/bin/rm -f pull.add.image.failed.list pull.add.image.ok.list yaml.add.image.ok.list

export LOCAL_REG='registry.redhat.ren'

source image.mirror.fn.sh

mkdir -p ./image_tar

while read -r line; do

    add_image $line

done < add.image.list




