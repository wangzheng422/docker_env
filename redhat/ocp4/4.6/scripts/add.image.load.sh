#!/usr/bin/env bash

set -e
set -x

parm_dir=$1
parm_registry=$2

# export MID_REG='registry-add.redhat.ren:5000'
export LOCAL_REG="$parm_registry"
# export MIRROR_DIR='/data/mirror_dir'
export MIRROR_DIR=${parm_dir}

/bin/rm -f pull.add.image.failed.list pull.add.image*.ok.list yaml.add.image.ok.list

source fn.sh

while read -r line; do

    add_image_load_oci_file $line

done < ${parm_dir}/pull.add.image.ok.list

while read -r line; do

    add_image_load_docker_file $line

done < ${parm_dir}/pull.add.image.docker.ok.list


# /bin/cp -f yaml.image.ok.list yaml.image.ok.list.tmp

# cat yaml.add.image.ok.list >> yaml.image.ok.list.tmp

# cat yaml.image.ok.list.tmp | sort | uniq > yaml.add.image.ok.list.uniq




