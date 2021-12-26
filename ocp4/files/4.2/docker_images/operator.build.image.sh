#!/usr/bin/env bash

set -e
set -x

cd /data/ocp4/operator/

var_date=$(date '+%Y-%m-%d')
echo $var_date

#####################################
# for redhat

tar zxf manifests.tgz

/bin/rm -rf ./manifests/certified-operators.*
/bin/rm -rf ./manifests/community-operators.*

# docker build --no-cache -f ./custom-registry.Dockerfile -t docker.io/wangzheng422/custom-registry-redhat:$var_date ./

# docker push docker.io/wangzheng422/custom-registry-redhat:${var_date}

buildah from --name onbuild-container registry.redhat.io/openshift4/ose-operator-registry:latest
buildah copy onbuild-container manifests.tgz manifests.tgz
buildah copy onbuild-container manifests manifests
buildah run onbuild-container /bin/initializer -o ./bundles.db
buildah umount onbuild-container 
buildah config -p 50051 onbuild-container
buildah config --entrypoint '["/usr/bin/registry-server"]' onbuild-container
buildah config --cmd '["--database", "/registry/bundles.db"]' onbuild-container
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/custom-registry-redhat:${var_date}
buildah push docker.io/wangzheng422/custom-registry-redhat:${var_date}

# podman tag quay.io/wangzheng422/custom-registry-redhat:${var_date} quay.io/wangzheng422/custom-registry-redhat:latest
# podman push quay.io/wangzheng422/custom-registry-redhat:latest

# podman image save registry.redhat.ren/ocp-operator/custom-registry:redhat | pigz -c > custom-registry.redhat.tgz

##################################
# for certifiyed

tar zxf manifests.tgz

/bin/rm -rf ./manifests/redhat-operators.*
/bin/rm -rf ./manifests/community-operators.*

# docker build --no-cache -f ./custom-registry.Dockerfile -t docker.io/wangzheng422/custom-registry-certified:$var_date ./
# docker push docker.io/wangzheng422/custom-registry-certified:$var_date

buildah from --name onbuild-container registry.redhat.io/openshift4/ose-operator-registry:latest
buildah copy onbuild-container manifests.tgz manifests.tgz
buildah copy onbuild-container manifests manifests
buildah run onbuild-container /bin/initializer -o ./bundles.db
buildah umount onbuild-container 
buildah config -p 50051 onbuild-container
buildah config --entrypoint '["/usr/bin/registry-server"]' onbuild-container
buildah config --cmd '["--database", "/registry/bundles.db"]' onbuild-container
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/custom-registry-certified:$var_date
buildah push docker.io/wangzheng422/custom-registry-certified:$var_date

# podman tag quay.io/wangzheng422/custom-registry-certified:${var_date} quay.io/wangzheng422/custom-registry-certified:latest
# podman push quay.io/wangzheng422/custom-registry-certified:latest

# podman image save registry.redhat.ren/ocp-operator/custom-registry:certified | pigz -c > custom-registry.certified.tgz

####################################
# for community

tar zxf manifests.tgz

/bin/rm -rf ./manifests/redhat-operators.*
/bin/rm -rf ./manifests/certified-operators.*

# docker build --no-cache -f ./custom-registry.Dockerfile -t docker.io/wangzheng422/custom-registry-community:$var_date ./
# docker push docker.io/wangzheng422/custom-registry-community:$var_date

buildah from --name onbuild-container registry.redhat.io/openshift4/ose-operator-registry:latest
buildah copy onbuild-container manifests.tgz manifests.tgz
buildah copy onbuild-container manifests manifests
buildah run onbuild-container /bin/initializer -o ./bundles.db
buildah umount onbuild-container 
buildah config -p 50051 onbuild-container
buildah config --entrypoint '["/usr/bin/registry-server"]' onbuild-container
buildah config --cmd '["--database", "/registry/bundles.db"]' onbuild-container
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/custom-registry-community:$var_date
buildah push docker.io/wangzheng422/custom-registry-community:$var_date

# podman tag quay.io/wangzheng422/custom-registry-community:${var_date} quay.io/wangzheng422/custom-registry-community:latest
# podman push quay.io/wangzheng422/custom-registry-community:latest

# podman image save registry.redhat.ren/ocp-operator/custom-registry:community | pigz -c > custom-registry.community.tgz

#####################################
## restore

tar zxf manifests.tgz

cd /data/ocp4

# find ./operator -type f | xargs grep "image: " | sed 's/^.*image: //' | sort | uniq | grep -e '^.*\/.*:.*' | grep -v '\\n' | sed s/"'"//g | sed 's/\"//g' | sort | uniq >  /data/ocp4/operator.image.list

# find ./operator -type f | xargs cat | egrep "^.*\.(io|com|org|net)/[[:print:]]*:[[:print:]]*"  | sed 's/\\n/\n/g'| sed 's/^.*containerImage: //' | sed 's/^.*image: //' | sed 's/^.*value: //' | egrep "^.*\.(io|com|org|net)/.*:.*" | sed s/"'"//g | sed 's/\"//g' | sort | uniq  > /data/ocp4/operator.image.list





