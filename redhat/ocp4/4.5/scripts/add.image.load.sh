#!/usr/bin/env bash

set -e
set -x

parm_dir=$1

# export MID_REG='registry-add.redhat.ren:5000'
export LOCAL_REG='registry.redhat.ren:5443'
# export MIRROR_DIR='/data/mirror_dir'
export MIRROR_DIR=${parm_dir}

/bin/rm -f pull.add.image.failed.list pull.add.image*.ok.list yaml.add.image.ok.list

source image.mirror.fn.sh

# cd /data
# rm -rf mirror_dir
# tar zxf mirror_dir.tgz 

# cd /data/ocp4
# cd ${parm_dir}

# while read -r line; do

#     delimiter="\t"
#     declare -a array=($(echo $line | tr "$delimiter" " "))
#     docker_image=${array[0]}
#     tar_file_name=${array[1]}
#     local_image_url=${array[2]}

#     skopeo copy "docker-archive:./image_tar/"$tar_file_name "docker://"$local_image_url

# done < pull.add.image.ok.list

while read -r line; do

    add_image_load_oci_file $line

done < ${parm_dir}/pull.add.image.ok.list

while read -r line; do

    add_image_load_docker_file $line

done < ${parm_dir}/pull.add.image.docker.ok.list


# /bin/cp -f yaml.image.ok.list yaml.image.ok.list.tmp

# cat yaml.add.image.ok.list >> yaml.image.ok.list.tmp

# cat yaml.image.ok.list.tmp | sort | uniq > yaml.add.image.ok.list.uniq




