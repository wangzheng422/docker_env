#!/usr/bin/env bash

set -e
set -x

split_image(){

    docker_image=$1
    echo $docker_image
    var_skip=0

    sha_part=$(echo ${docker_image} | sha1sum | cut -f 1 -d ' ')

    if [[ "$docker_image" =~ ^$ ]] || [[ "$docker_image" =~ ^[[:space:]]+$ ]] || [[ "$docker_image" =~ \#[:print:]*  ]]; then
        # echo "this is comments"
        var_skip=1
        return;
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*@sha256:.* ]]; then
        # echo "io, com, org with tag: $docker_image"

        image_part=${docker_image%@*}

        local_image_url="${image_part}:${sha_part}"

    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*:.* ]]; then
        # echo "io, com, org with tag: $docker_image"

        local_image_url="$docker_image"

    elif [[ $docker_image =~ ^.*\.(io|com|org)/[^:]*  ]]; then
        # echo "io, com, org without tag: $docker_image"

        docker_image+=":latest"

        local_image_url="$docker_image"

    elif [[ $docker_image =~ ^.*/.*@sha256:.* ]]; then
        # echo "docker with tag: $docker_image"

        docker_image="docker.io/${docker_image}"        

        image_part=${docker_image%@*}

        local_image_url="${image_part}:${sha_part}"

    elif [[ $docker_image =~ ^.*/.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        docker_image="docker.io/${docker_image}"        

        local_image_url="$docker_image"

    elif [[ $docker_image =~ ^.*/[^:]* ]]; then
        # echo "docker without tag: $docker_image"
        docker_image="docker.io/${docker_image}:latest"        

        local_image_url="$docker_image"

    elif [[ $docker_image =~ ^.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        docker_image="docker.io/library/${docker_image}"       

        local_image_url="$docker_image"

    fi

}

add_image_file() {

    var_line=$1
    split_image $var_line

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        # if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        # if oc image mirror --filter-by-os='.*' -a /data/pull-secret.json --dir=${MIRROR_DIR}/oci/ $docker_image file://$local_image_url ; then
        if oc image mirror --filter-by-os=linux/amd64 --keep-manifest-list=true -a /data/pull-secret.json --dir=${MIRROR_DIR}/oci/ $docker_image file://$local_image_url ; then
            echo -e "${docker_image}" >> pull.add.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
            # echo -e "${domain_part}" >> yaml.add.image.ok.list
        else
            # try to convert oci to docker
            if buildah from --name onbuild-container ${docker_image}; then
                buildah unmount onbuild-container
                buildah commit --format=docker onbuild-container ${docker_image}
                buildah rm onbuild-container
                buildah push ${docker_image} docker-archive:/${MIRROR_DIR}/docker/$sha_part
                echo -e "${docker_image}\t${MIRROR_DIR}/docker/$sha_part" >> pull.add.image.docker.ok.list
                # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
                # echo -e "${domain_part}" >> yaml.add.image.ok.list
            else
                echo "$docker_image" >> pull.add.image.failed.list
            fi
        fi
    fi
}



add_image_load_oci_file() {

    docker_image=$1

    split_image $docker_image

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        # if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        if oc image mirror --filter-by-os=linux/amd64 --keep-manifest-list=true --from-dir=${MIRROR_DIR}/oci/ file://$local_image_url $local_image_dest ; then
            echo -e "${docker_image}" >> pull.add.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
            # echo -e "${domain_part}" >> yaml.add.image.ok.list
        else
            echo "$docker_image" >> pull.add.image.failed.list
        fi
    fi
}
