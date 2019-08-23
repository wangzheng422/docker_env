#!/usr/bin/env bash

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

pull_docker_image(){
    docker_images=$1
    save_file=$2
    list_file=$3

    echo > $list_file

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then
            if [[ -z $(docker images -q $line) ]]; then
                if docker pull $line; then
                    echo $line >> $list_file
                else
                    echo "# $line">> $list_file
                fi
            else
                echo $line >> $list_file
            fi
        else
            echo $line >> $list_file
        fi

        if [ ! -z "$sleep_time" ]; then
            sleep $sleep_time
        fi
    done <<< "$docker_images"

}

load_redhat_image(){

    docker_images=$1
    split_tag=$2
    list_file=$3

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then
            # part1=$(echo "$line" | awk  '{split($0,a,"$split_tag"); print a[2]}')
            # https://stackoverflow.com/questions/19885660/shell-script-command-to-split-string-using-a-variable-delimiter
            # front = ${line%${split_tag}*}
            part1=${line#*${split_tag}}
            part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
            part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
            if [[ "$part3" =~ [^[:space:]] ]]; then
                docker tag $line $private_repo$part2:$part3
                docker push $private_repo$part2:$part3
                docker tag $line $private_repo$part2:$major_tag
                docker push $private_repo$part2:$major_tag
                docker tag $line $private_repo$part2:$tag
                docker push $private_repo$part2:$tag
                docker tag $line $private_repo$part2
                docker push $private_repo$part2
            else
                docker tag $line $private_repo$part2
                docker push $private_repo$part2
                docker tag $line $private_repo$part2:$major_tag
                docker push $private_repo$part2:$major_tag
                docker tag $line $private_repo$part2:$tag
                docker push $private_repo$part2:$tag
            fi
            
        fi
    done < $list_file
}

load_docker_image(){

    docker_images=$1

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then

            part2=$(echo $line | awk  '{split($0,a,":"); print a[1]}')
            part3=$(echo $line | awk  '{split($0,a,":"); print a[2]}')
            if [ -z "$part3" ]; then
                docker tag $line $private_repo/$part2
                docker push $private_repo/$part2
            else
                docker tag $line $private_repo/$part2:$part3
                docker push $private_repo/$part2:$part3
            fi
        fi
    done <<< "$docker_images"
}

remove_docker_image(){
    docker_images=$1
    split_tag=$2
    list_file=$3

    cmd_img_str=" "

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then
            # part1=$(echo $line | awk  '{split($0,a,$split_tag); print a[2]}')
            part1=${line#*${split_tag}}
            part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
            part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
            if [[ "$part3" =~ [^[:space:]] ]]; then
                cmd_img_str+=" $private_repo$part2:$part3"
                cmd_img_str+=" $private_repo$part2:$major_tag"
                cmd_img_str+=" $private_repo$part2:$tag"
                cmd_img_str+=" $private_repo$part2"
            else
                cmd_img_str+=" $private_repo$part2"
                cmd_img_str+=" $private_repo$part2:$major_tag"
                cmd_img_str+=" $private_repo$part2:$tag"
            fi
            cmd_img_str+=" $line";
        fi
    done < $list_file

    docker image rm -f $cmd_img_str
}

#################################
## pull and dump images

pull_docker_image "$ose3_images" "ose3-images.tgz" "ose3-images.list"
load_redhat_image "$ose3_images" "redhat.io" "ose3-images.list"
# remove_docker_image "$ose3_images" "redhat.io"  "ose3-images.list"
docker image rm -f $(docker image ls -qa)

# pull_docker_image "$ose3_optional_imags" "ose3-optional-imags.tgz" "ose3-optional-imags.list"

# pull_docker_image "$ose3_builder_images" "ose3-builder-images.tgz" "ose3-builder-images.list"

# pull_docker_image "$cnv_optional_imags" "cnv-optional-images.tgz" "cnv-optional-images.list"

# pull_docker_image "$istio_optional_imags" "istio-optional-images.tgz" "istio-optional-images.list"

# pull_docker_image "$docker_builder_images" "docker-builder-images.tgz" "docker-builder-images.list"

# pull_docker_image "$quay_builder_images" "quay-builder-images.tgz" "quay-builder-images.list"

# pull_docker_image "$gcr_builder_images" "gcr-builder-images.tgz" "gcr-builder-images.list"

# pull_docker_image "$nvcr_builder_images" "nvcr-builder-images.tgz" "nvcr-builder-images.list"

##################################

docker image prune -f



