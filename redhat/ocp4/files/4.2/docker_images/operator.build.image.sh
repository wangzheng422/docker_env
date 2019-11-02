#!/usr/bin/env bash

set -e
set -x

cd /data/ocp4/operator/

podman build -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry:all ./

podman image save registry.redhat.ren/ocp-operator/custom-registry:all | pigz -c > custom-registry.all.tgz

/bin/rm -rf ./manifests/community-operators.*

podman build -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry:certified ./

podman image save registry.redhat.ren/ocp-operator/custom-registry:community | pigz -c > custom-registry.certified.tgz

/bin/rm -rf ./manifests/certified-operators.*

podman build -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry:redhat ./

podman image save registry.redhat.ren/ocp-operator/custom-registry:community | pigz -c > custom-registry.redhat.tgz

# find ./operator -type f | xargs grep "image: " | sed 's/^.*image: //' | sort | uniq | grep -e '^.*\/.*:.*' | grep -v '\\n' | sed s/"'"//g | sed 's/\"//g' | sort | uniq >  /data/ocp4/operator.image.list

# find ./operator -type f | xargs cat | egrep "^.*\.(io|com|org|net)/[[:print:]]*:[[:print:]]*"  | sed 's/\\n/\n/g'| sed 's/^.*containerImage: //' | sed 's/^.*image: //' | sed 's/^.*value: //' | egrep "^.*\.(io|com|org|net)/.*:.*" | sed s/"'"//g | sed 's/\"//g' | sort | uniq  > /data/ocp4/operator.image.list





