#!/usr/bin/env bash

set -e
set -x

parm_file=$1

/bin/rm -f pull.add.image.failed.list pull.add.image*.ok.list yaml.add.image.ok.list

touch pull.add.image.ok.list
touch pull.add.image.docker.ok.list

export MIRROR_DIR='/data/mirror_dir'
/bin/rm -rf ${MIRROR_DIR}
mkdir -p ${MIRROR_DIR}/oci
mkdir -p ${MIRROR_DIR}/docker
export LOCAL_REG=''

source image.mirror.fn.sh

# mkdir -p ./image_tar
# /bin/rm -rf /data/registry-add

# mkdir -p /data/registry-add
# mkdir -p /data/ocp4/certs
# mkdir -p /data/registry-add
# cp /etc/crts/redhat.ren.crt /data/ocp4/certs
# cp /etc/crts/redhat.ren.key /data/ocp4/certs

# podman run -d --name mirror-registry \
# -p 5000:5000 --restart=always \
# -v /data/registry-add:/var/lib/registry:z \
# -v /data/ocp4/certs:/certs:z \
# -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/redhat.ren.crt \
# -e REGISTRY_HTTP_TLS_KEY=/certs/redhat.ren.key \
# docker.io/library/registry:2

while read -r line; do

    add_image_file $line

done < ${parm_file}  # add.image.list

/bin/cp -f pull.add.image.ok.list ${MIRROR_DIR}/
/bin/cp -f pull.add.image.docker.ok.list ${MIRROR_DIR}/

cd /data
tar cf - mirror_dir/ | pigz -c > mirror_dir.tgz 




