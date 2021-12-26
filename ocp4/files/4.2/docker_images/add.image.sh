#!/usr/bin/env bash

set -e
set -x

/bin/rm -f pull.add.image.failed.list pull.add.image.ok.list yaml.add.image.ok.list

export LOCAL_REG='registry.redhat.ren:5000'

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

    add_image $line

done < add.image.list

# cd /data
# tar cf - registry-add/ | pigz -c > registry-add.tgz 




