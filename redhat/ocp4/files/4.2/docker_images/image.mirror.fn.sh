#!/usr/bin/env bash

set -e
set -x


mirror_image(){

    docker_image=$1
    echo $docker_image

    if [[ "$docker_image" =~ ^$ ]] || [[ "$docker_image" =~ ^[[:space:]]+$ ]] || [[ "$docker_image" =~ \#[:print:]*  ]]; then
        # echo "this is comments"
        return;
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*@sha256:.* ]]; then
        # echo "io, com, org with tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}"
        image_part=$(echo $image_part | sed -r 's/@sha256:.*$//')
        sha_part==$(echo $image_part | sed -r 's/.*@sha256://')
        sha_part=$(cksum <<< ${sha_part} | cut -f 1 -d ' ')
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}:${sha_part}"

        yaml_image=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        yaml_local_image="${LOCAL_REG}/${domain_part}${image_part}"
        # echo $image_url
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*:.* ]]; then
        # echo "io, com, org with tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}"
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}"

        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')
        # echo $image_url
    elif [[ $docker_image =~ ^.*\.(io|com|org)/[^:]*  ]]; then
        # echo "io, com, org without tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}:latest"
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}:latest"
        # echo $image_url

        yaml_image=$docker_image

        docker_image+=":latest"

        yaml_local_image="${LOCAL_REG}/${domain_part}${image_part}"
    elif [[ $docker_image =~ ^.*/.*@sha256:.* ]]; then
        # echo "docker with tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        image_part=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        sha_part==$(echo $image_part | sed -r 's/.*@sha256://')
        sha_part=$(cksum <<< ${sha_part} | cut -f 1 -d ' ')
        local_image_url="${LOCAL_REG}/docker.io/${image_part}:${sha_part}"
        
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        yaml_local_image="${LOCAL_REG}/docker.io/${image_part}"
    elif [[ $docker_image =~ ^.*/.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')
    elif [[ $docker_image =~ ^.*/[^:]* ]]; then
        # echo "docker without tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}:latest"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}:latest"

        yaml_image=$docker_image
        yaml_local_image="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        docker_image+="${docker_image}:latest"

    elif [[ $docker_image =~ ^.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')

        docker_image="${docker_image}"

    fi

    # if oc image mirror $docker_image $local_image_url; then
    if skopeo copy "docker://"$docker_image "docker://"$local_image_url; then
        echo -e "${docker_image}\t${local_image_url}" >> pull.image.ok.list
        echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.image.ok.list
    else
        echo "$docker_image" >> pull.image.failed.list
    fi

}

shorten_image(){

    docker_image=$1
    echo $docker_image

    if [[ "$docker_image" =~ ^$ ]] || [[ "$docker_image" =~ ^[[:space:]]+$ ]] || [[ "$docker_image" =~ \#[:print:]*  ]]; then
        # echo "this is comments"
        return;
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*@sha256:.* ]]; then
        # echo "io, com, org with tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}"
        image_part=$(echo $image_part | sed -r 's/@sha256:.*$//')
        sha_part==$(echo $image_part | sed -r 's/.*@sha256://')
        sha_part=$(cksum <<< ${sha_part} | cut -f 1 -d ' ')
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}:${sha_part}"

        yaml_image=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        yaml_local_image="${LOCAL_REG}/${domain_part}${image_part}"
        # echo $image_url
    elif [[ $docker_image =~ ^.*\.(io|com|org)/.*:.* ]]; then
        # echo "io, com, org with tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}"
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}"

        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')
        # echo $image_url
    elif [[ $docker_image =~ ^.*\.(io|com|org)/[^:]*  ]]; then
        # echo "io, com, org without tag: $docker_image"
        domain_part=$(echo $docker_image | cut -d'/' -f1)
        image_part=$(echo $docker_image | sed -r 's/^.*\.(io|com|org)//')
        local_image="${LOCAL_REG}/${domain_part}${image_part}:latest"
        local_image_url="${LOCAL_REG}/${domain_part}${image_part}:latest"
        # echo $image_url

        yaml_image=$docker_image

        docker_image+=":latest"

        yaml_local_image="${LOCAL_REG}/${domain_part}${image_part}"
    elif [[ $docker_image =~ ^.*/.*@sha256:.* ]]; then
        # echo "docker with tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        image_part=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        sha_part==$(echo $image_part | sed -r 's/.*@sha256://')
        sha_part=$(cksum <<< ${sha_part} | cut -f 1 -d ' ')
        local_image_url="${LOCAL_REG}/docker.io/${image_part}:${sha_part}"
        
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/@sha256:.*$//')
        yaml_local_image="${LOCAL_REG}/docker.io/${image_part}"
    elif [[ $docker_image =~ ^.*/.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')
    elif [[ $docker_image =~ ^.*/[^:]* ]]; then
        # echo "docker without tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}:latest"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}:latest"

        yaml_image=$docker_image
        yaml_local_image="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        docker_image+="${docker_image}:latest"

    elif [[ $docker_image =~ ^.*:.* ]]; then
        # echo "docker with tag: $docker_image"
        local_image="${LOCAL_REG}/docker.io/${docker_image}"
        local_image_url="${LOCAL_REG}/docker.io/${docker_image}"
        # echo $image_url
        yaml_image=$(echo $docker_image | sed -r 's/:.*$//')
        yaml_local_image=$(echo $local_image_url | sed -r 's/:.*$//')

        docker_image="${docker_image}"

    fi


    echo -e "${yaml_image}\t${yaml_local_image}" >> yaml.image.ok.list


}




