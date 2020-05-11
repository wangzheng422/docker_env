#!/usr/bin/env bash

set -e
set -x

export STATIC_MID_REG="registry.redhat.ren"

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
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}"
        image_part=$(echo $image_part | sed -r 's/@sha256:.*$//')
        # sha_part_var=$(echo $image_part | sed -r 's/.*@sha256://')
        sha_part=$(echo ${docker_image} | sha1sum | cut -f 1 -d ' ')
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}:${sha_part}"

        yaml_image=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        yaml_local_image="${STATIC_MID_REG}/${domain_part}${image_part}"
        # echo $image_url
        
        local_image_url_without_domain="${LOCAL_REG}/${image_part}:${sha_part}"
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*:.* ]]; then
        # echo "io, com, org with tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}"
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}"

        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image="${STATIC_MID_REG}/${yaml_image}"
        # echo $image_url
        local_image_url_without_domain="${LOCAL_REG}/${image_part}"
    elif [[ $docker_image =~ ^.*\.(io|com|org)/[^:]*  ]]; then
        # echo "io, com, org without tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}:latest"
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}:latest"
        # echo $image_url

        yaml_image=$docker_image

        docker_image+=":latest"

        yaml_local_image="${STATIC_MID_REG}/${domain_part}${image_part}"

        local_image_url_without_domain="${LOCAL_REG}/${image_part}:latest"
    elif [[ $docker_image =~ ^.*/.*@sha256:.* ]]; then
        # echo "docker with tag: $docker_image"
        domain_part="docker.io"

        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        image_part=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        # sha_part_var=$(echo $image_part | sed -r 's/.*@sha256://')
        sha_part=$(echo ${docker_image} | sha1sum | cut -f 1 -d ' ')
        local_image_url="${LOCAL_REG}/docker.io/${image_part}:${sha_part}"
        
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        yaml_local_image="${STATIC_MID_REG}/docker.io/${image_part}"

        local_image_url_without_domain="${LOCAL_REG}/${image_part}:${sha_part}"
    elif [[ $docker_image =~ ^.*/.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        domain_part="docker.io"

        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        # yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')
        yaml_local_image=$(echo "${STATIC_MID_REG}/docker.io/${docker_image}" | sed -r 's/:.*$//')

        local_image_url_without_domain="${LOCAL_REG}/${docker_image}"
    elif [[ $docker_image =~ ^.*/[^:]* ]]; then
        # echo "docker without tag: $docker_image"
        domain_part="docker.io"

        local_image="${LOCAL_REG}/docker.io/${docker_image}:latest"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}:latest"

        yaml_image=$docker_image
        yaml_local_image="${STATIC_MID_REG}/docker.io/${docker_image}"
        # echo $image_url
        docker_image+="${docker_image}:latest"

        local_image_url_without_domain="${LOCAL_REG}/${docker_image}:latest"
    elif [[ $docker_image =~ ^.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        domain_part="docker.io"

        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        # yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')
        yaml_local_image=$(echo "${STATIC_MID_REG}/docker.io/${docker_image}" | sed -r 's/:.*$//')

        # docker_image="${docker_image}"

        local_image_url_without_domain="${LOCAL_REG}/${docker_image}"

    fi

}

mirror_image() {

    var_line=$1
    split_image $var_line

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        # if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        if oc image mirror $docker_image $local_image_url; then
            echo -e "${docker_image}\t${local_image_url}" >> pull.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.image.ok.list
            echo -e "${domain_part}" >> yaml.image.ok.list
        else
            # try to convert oci to docker
            if buildah from --name onbuild-container ${docker_image}; then
                buildah unmount onbuild-container
                buildah commit --format=docker onbuild-container ${local_image_url}
                buildah rm onbuild-container
                buildah push ${local_image_url}
                echo -e "${docker_image}\t${local_image_url}" >> pull.image.ok.list
                echo -e "${docker_image}\t${local_image_url}" >> pull.image.docker.ok.list
                # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.image.ok.list
                # echo -e "${domain_part}" >> yaml.image.ok.list
            else
                echo "$docker_image" >> pull.image.failed.list
            fi
            
        fi
    fi
}

add_image_file() {

    var_line=$1
    split_image $var_line

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        # if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        if oc image mirror -a /data/pull-secret.json --dir=${MIRROR_DIR}/oci/ $docker_image file://$local_image_url ; then
            echo -e "${docker_image}\t${local_image_url}" >> pull.add.image.ok.list
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

    var_docker_image=$1
    file_name=$2

    split_image $var_docker_image

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        # if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        if oc image mirror --from-dir=${MIRROR_DIR}/oci/ file:/${file_name} $local_image_url ; then
            echo -e "${docker_image}\t${local_image_url}" >> pull.add.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
            # echo -e "${domain_part}" >> yaml.add.image.ok.list
        else
            echo "$docker_image" >> pull.add.image.failed.list
        fi
    fi
}

add_image_load_docker_file() {

    var_docker_image=$1
    file_name=$2

    split_image $var_docker_image

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        if skopeo copy docker-archive:/${MIRROR_DIR}/docker/${sha_part} "docker://"$local_image_url; then
        # if oc image mirror --from-dir=${MIRROR_DIR}/oci/ file:/${file_name} $local_image_url ; then
            echo -e "${docker_image}\t${local_image_url}" >> pull.add.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
            # echo -e "${domain_part}" >> yaml.add.image.ok.list
        else
            echo "$docker_image" >> pull.add.image.failed.list
        fi
    fi
}


add_image_load_oci_file_without_domain() {

    var_docker_image=$1
    file_name=$2

    split_image $var_docker_image

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        # if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        if oc image mirror --from-dir=${MIRROR_DIR}/oci/ file:/${file_name} $local_image_url_without_domain ; then
            echo -e "${docker_image}\t${local_image_url}" >> pull.add.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
            # echo -e "${domain_part}" >> yaml.add.image.ok.list
        else
            echo "$docker_image" >> pull.add.image.failed.list
        fi
    fi
}

add_image_load_docker_file_without_domain() {

    var_docker_image=$1
    file_name=$2

    split_image $var_docker_image

    # if oc image mirror $docker_image $local_image_url; then
    if [[ $var_skip == 0 ]]; then
        if skopeo copy docker-archive:/${MIRROR_DIR}/docker/${sha_part} "docker://"$local_image_url_without_domain; then
        # if oc image mirror --from-dir=${MIRROR_DIR}/oci/ file:/${file_name} $local_image_url ; then
            echo -e "${docker_image}\t${local_image_url}" >> pull.add.image.ok.list
            # echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.add.image.ok.list
            # echo -e "${domain_part}" >> yaml.add.image.ok.list
        else
            echo "$docker_image" >> pull.add.image.failed.list
        fi
    fi
}



