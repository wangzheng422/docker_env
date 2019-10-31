#!/usr/bin/env bash

set -e
set -x

/bin/rm -rf /data/operator/manifests
/bin/rm -f operator.ok operator.failed
mkdir -p /data/operator/manifests
cd /data/operator/

curl https://quay.io/cnr/api/v1/packages?namespace=redhat-operators > packages.txt
curl https://quay.io/cnr/api/v1/packages?namespace=certified-operators >> packages.txt
curl https://quay.io/cnr/api/v1/packages?namespace=community-operators >> packages.txt

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

    curl -XGET https://quay.io/cnr/api/v1/packages/$namespace/$name/blobs/sha256/$digest -o tgz/$namespace.$name.$release.tar.gz

    mkdir -p manifests/${namespace}.$name/ 

    string=$(tar --exclude='*/*' -tf tgz/$namespace.$name.$release.tar.gz)
    case $string in
        */) echo "end with /"
            tar --strip 1 -xf tgz/$namespace.$name.$release.tar.gz -C manifests/${namespace}.$name/;;
        *) echo "end with file"
            tar -xf tgz/$namespace.$name.$release.tar.gz -C manifests/${namespace}.$name/;;
    esac

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

    fi  

    /bin/rm -f manifests/${namespace}.$name/bundle.yaml

    if podman build -f ../custom-registry.Dockerfile -t registry.redhat.ren/ocp-operator/custom-registry ./ ; then
        echo "$line" >> ../operator.ok
    else
        echo "$line" >> ../operator.failed
        /bin/rm -rf manifests/${namespace}.$name
    fi

    podman image prune

done < url.txt

podman image save registry.redhat.ren/ocp-operator/custom-registry | pigz -c > custom-registry.tgz

cd /data/operator
tar zcf manifests.tgz manifests/



