#!/usr/bin/env bash

set -e
set -x

var_date=$(date '+%Y.%m.%d.%H%M')
echo $var_date
export var_major_version='4.6'
echo ${var_major_version}

# https://docs.openshift.com/container-platform/4.6/operators/admin/olm-restricted-networks.html

cd /data/ocp4
/bin/rm -rf /data/ocp4/operator
/bin/rm -f operator.ok.list operator.failed.list
mkdir -p /data/ocp4/operator/manifests
mkdir -p /data/ocp4/operator/tgz
cd /data/ocp4/operator/

curl https://quay.io/cnr/api/v1/packages?namespace=redhat-operators > packages.txt
curl https://quay.io/cnr/api/v1/packages?namespace=certified-operators >> packages.txt
curl https://quay.io/cnr/api/v1/packages?namespace=community-operators >> packages.txt
curl https://quay.io/cnr/api/v1/packages?namespace=redhat-marketplace >> packages.txt

cat packages.txt | jq -r ".[] | [.namespace, .name, .releases[0]] | @tsv" | awk -v FS="\t" '{printf "https://quay.io/cnr/api/v1/packages/%s/%s\t%s\t%s%s",$2,$3,$2,$3,ORS}' > url.txt

while read -r line; do
#   echo $line;
    delimiter="\t"
    declare -a array=($(echo $line | tr "$delimiter" " "))
    url=${array[0]}
    var2=${array[1]}
    release=${array[2]}

    delimiter="/"
    declare -a array=($(echo $var2 | tr "$delimiter" " "))
    namespace=${array[0]}
    name=${array[1]}

    echo $url
    echo $namespace
    echo $name
    echo $release

    digest=$(curl https://quay.io/cnr/api/v1/packages/$namespace/$name/$release | jq -r ".[] | .content.digest")

    # metadata=$(curl https://quay.io/cnr/api/v1/packages/$namespace/$name/$release | jq -r ".[] | .content.metadata")

    curl -XGET https://quay.io/cnr/api/v1/packages/$namespace/$name/blobs/sha256/$digest -o tgz/$namespace.$name.$release.tar.gz

    mkdir -p manifests/${namespace}.$name/ 

    # string=$(tar --exclude='*/*' -tf tgz/$namespace.$name.$release.tar.gz)
    if [ -z "$(tar --exclude='*/*' -tf tgz/$namespace.$name.$release.tar.gz | grep -v \/ ) "]; then
        # only directory 
        tar --strip 1 -xf tgz/$namespace.$name.$release.tar.gz -C manifests/${namespace}.$name/
    else
        # contains files
        tar -xf tgz/$namespace.$name.$release.tar.gz -C manifests/${namespace}.$name/
    fi

    if [ -f "manifests/${namespace}.$name/bundle.yaml" ]; then

        csv_num=$(cat manifests/${namespace}.$name/bundle.yaml | yq -r .data.clusterServiceVersions | yq length)

        for (( csv_i=0; csv_i<$csv_num; csv_i++ ))
        do
            mkdir -p manifests/${namespace}.$name/$csv_i

            cat manifests/${namespace}.$name/bundle.yaml | yq -r .data.clusterServiceVersions | yq -y .[$csv_i]  > manifests/${namespace}.$name/$csv_i/clusterserviceversion-$csv_i.yaml

            num=$(cat manifests/${namespace}.$name/bundle.yaml | yq -r .data.customResourceDefinitions | yq length)

            for (( i=0; i<$num; i++ ))
            do
                cat manifests/${namespace}.$name/bundle.yaml | yq -r .data.customResourceDefinitions | yq -y .[$i]  > manifests/${namespace}.$name/$csv_i/customresourcedefinition-$i.yaml
            done
        done
        
        cat manifests/${namespace}.$name/bundle.yaml | yq -r .data.packages | sed 's/^..//' > manifests/${namespace}.$name/package.yaml 

        # echo "with bundle: $line" >> /data/ocp4/operator.ok.list
    # else
        # echo "ok: $line" >> /data/ocp4/operator.failed.list
    fi  

    # /bin/rm -f manifests/${namespace}.$name/bundle.yaml

    # if podman build -f /data/ocp4/custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry ./ ; then
    #     echo "$line" >> /data/ocp4/operator.ok.list
    # else
    #     echo "$line" >> /data/ocp4/operator.failed.list
    #     /bin/rm -rf manifests/${namespace}.$name
    # fi

    # podman image prune

done < url.txt

# cd /data/ocp4/operator
# chown -R 1001:1001 *
# tar zcf manifests.tgz manifests/

cd /data/ocp4

# find ./operator -type f | xargs egrep "(containerImage: |image: |value: )" | sed 's/\\n/\n/g'| sed 's/^.*containerImage: //' | sed 's/^.*image: //' | sed 's/^.*value: //' | egrep "^.*\.(io|com|org|net)/.*:.*" | sed s/"'"//g | sed 's/\"//g' | sort | uniq  > /data/ocp4/operator.image.list

# find ./operator -type f | xargs egrep "(containerImage: |image: |value: )" | sed 's/\\n/\n/g'| sed 's/^.*image: //' | sed 's/^.*value: //' | egrep -v "^.*\.(io|com|org|net)/.*:.*"| egrep  "^[[:alnum:]]*/.*:[[:print:]]*$" | sed s/"'"//g | sed 's/\"//g' | sort | uniq  >> /data/ocp4/operator.image.list

# find ./manifests -type f | xargs egrep -h "=[[:alnum:]|\.]+\.(io|com|org|net)/[[:graph:]]+$" | grep -v "apiVersion:" | grep -v "version:" 

# find ./manifests -type f | xargs egrep -h " [[:alnum:]|\.]+\.(io|com|org|net)/[[:graph:]]+$" | grep -v "apiVersion:" | grep -v "version:" 

find ./operator/manifests -type f | xargs egrep -oh " [[:alnum:]|\.]+/[[:graph:]]+:[[:graph:]]+$" | sed 's/\\n/\n/g' | egrep -o "[[:alnum:]|\.]+/[[:graph:]]+:[[:graph:]]+$" | grep -v "\*\*" | sed "s/'//g" > /data/ocp4/operator.image.list

find ./operator/manifests -type f | xargs egrep -oh "=[[:alnum:]|\.]+/[[:graph:]]+:[[:graph:]]+$" | egrep -o "[[:alnum:]|\.]+/[[:graph:]]+:[[:graph:]]+$" | sed "s/'//g" >> /data/ocp4/operator.image.list

find ./operator/manifests -type f | xargs egrep -oh " [[:alnum:]|\.]+\.(io|com|org|net)/[[:graph:]]+$" | sed 's/\\n/\n/g' | grep -v "/v1" | grep -v "github.com" | grep -v "discovery.3scale.net" | egrep -o "[[:alnum:]|\.]+\.(io|com|org|net)/[[:graph:]]+$" | sed "s/'//g" >> /data/ocp4/operator.image.list

find ./operator/manifests -type f | xargs egrep -oh "=[[:alnum:]|\.]+/[[:graph:]]+$" | sed 's/\\n/\n/g'  | egrep -o "[[:alnum:]|\.]+/[[:graph:]]+$" | sed "s/'//g" >> /data/ocp4/operator.image.list

cat /data/ocp4/operator.image.list | grep "^[[:alnum:]].*[[:alnum:]]$" | sort | uniq > /data/ocp4/operator.image.list.uniq

# /bin/cp -f /data/ocp4/operator.image.list.uniq /data/ocp4/operator/operator.image.list.uniq

# cd /data/ocp4/operator
# chown -R 1001:1001 *
# tar zcf manifests.tgz manifests/

cd /data/ocp4/
chown -R 1001:1001 operator
tar zcf operator.tgz operator/

buildah from --name onbuild-container docker.io/library/centos:centos7
buildah copy onbuild-container operator.tgz /
buildah copy onbuild-container operator.image.list.uniq /
buildah umount onbuild-container 
buildah commit --rm --format=docker onbuild-container docker.io/wangzheng422/operator-catalog:fs-${var_major_version}-$var_date
# buildah rm onbuild-container
buildah push docker.io/wangzheng422/operator-catalog:fs-${var_major_version}-$var_date

echo docker.io/wangzheng422/operator-catalog:fs-${var_major_version}-$var_date
