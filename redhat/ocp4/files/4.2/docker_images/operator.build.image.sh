#!/usr/bin/env bash

set -e
set -x

cd /data/ocp4/operator/

#####################################
# for redhat

tar zxf manifests.tgz

/bin/rm -rf ./manifests/certified-operators.*
/bin/rm -rf ./manifests/community-operators.*

podman build --no-cache -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry:redhat ./

podman push registry.redhat.ren/ocp-operator/custom-registry:redhat

podman image save registry.redhat.ren/ocp-operator/custom-registry:redhat | pigz -c > custom-registry.redhat.tgz

##################################
# for certifiyed

tar zxf manifests.tgz

/bin/rm -rf ./manifests/redhat-operators.*
/bin/rm -rf ./manifests/community-operators.*

podman build --no-cache -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry:certified ./

podman push registry.redhat.ren/ocp-operator/custom-registry:certified

podman image save registry.redhat.ren/ocp-operator/custom-registry:certified | pigz -c > custom-registry.certified.tgz

####################################
# for community

tar zxf manifests.tgz

/bin/rm -rf ./manifests/redhat-operators.*
/bin/rm -rf ./manifests/certified-operators.*

podman build --no-cache -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry:community ./

podman push registry.redhat.ren/ocp-operator/custom-registry:community 

podman image save registry.redhat.ren/ocp-operator/custom-registry:community | pigz -c > custom-registry.community.tgz

cd /data/ocp4

# find ./operator -type f | xargs grep "image: " | sed 's/^.*image: //' | sort | uniq | grep -e '^.*\/.*:.*' | grep -v '\\n' | sed s/"'"//g | sed 's/\"//g' | sort | uniq >  /data/ocp4/operator.image.list

# find ./operator -type f | xargs cat | egrep "^.*\.(io|com|org|net)/[[:print:]]*:[[:print:]]*"  | sed 's/\\n/\n/g'| sed 's/^.*containerImage: //' | sed 's/^.*image: //' | sed 's/^.*value: //' | egrep "^.*\.(io|com|org|net)/.*:.*" | sed s/"'"//g | sed 's/\"//g' | sort | uniq  > /data/ocp4/operator.image.list





