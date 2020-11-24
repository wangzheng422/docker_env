#!/usr/bin/env bash

set -e
set -x

parm_file=$1
parm_dir=$2

/bin/rm -f pull.add.image.ok.list
/bin/rm -f pull.add.image.docker.ok.list
/bin/rm -f pull.add.image.failed.list

export MIRROR_DIR="$parm_dir"
# /bin/rm -rf ${MIRROR_DIR}
mkdir -p ${MIRROR_DIR}/oci
mkdir -p ${MIRROR_DIR}/docker

source fn.sh

while read -r line; do

    add_image_file $line

done < ${parm_file}  # add.image.list

cat pull.add.image.ok.list >> ${MIRROR_DIR}/pull.add.image.ok.list
cat pull.add.image.docker.ok.list >> ${MIRROR_DIR}/pull.add.image.docker.ok.list

# cd /data
# tar cf - mirror_dir/ | pigz -c > mirror_dir.tgz 




