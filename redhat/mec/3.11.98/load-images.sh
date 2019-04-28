#!/usr/bin/env bash

# exec 5> debug_output.txt
# BASH_XTRACEFD="5"
# PS4='$LINENO: '

set -e
set -x

dummy=$1

# mkdir -p tmp

## read configration
source config.sh

private_repo="registry.redhat.ren"
major_tag="v3.11"

load_redhat_image(){

    docker_images=$1
    split_tag=$2

    while read -r line; do
        if [[ "$line" =~ [^[:space:]] ]] && [[ !  "$line" =~ [\#][:print:]*  ]]; then
            part1=$(echo $line | awk  '{split($0,a,$split_tag); print a[2]}')
            part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
            part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
            if [[ "$part3" =~ [^[:space:]] ]]; then
                docker tag $line $private_repo$part2:$part3
                docker push $private_repo$part2:$part3
            else
                docker tag $line $private_repo$part2
                docker push $private_repo$part2
            fi
            
        fi
    done <<< "$docker_images"
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

#################################
## pull and dump images

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         part1=$(echo $line | awk '{split($0,a,"redhat.io"); print a[2]}')
#         part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
#         part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
#         docker tag $line $private_repo$part2:$tag
#         docker push "$private_repo$part2:$tag"
#         docker tag $line $private_repo$part2:$major_tag
#         docker push $private_repo$part2:$major_tag
#         docker tag $line $private_repo$part2
#         docker push $private_repo$part2
#     fi
# done <<< "$ose3_images"

load_redhat_image "$ose3_images" "redhat.io"


###################################
## pull and dump images

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         part1=$(echo $line | awk  '{split($0,a,"redhat.io"); print a[2]}')
#         part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
#         part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
#         docker tag $line $private_repo$part2:$part3
#         docker push $private_repo$part2:$part3
#         docker tag $line $private_repo$part2
#         docker push $private_repo$part2
#     fi
# done <<< "$ose3_optional_imags"

load_redhat_image "$ose3_optional_imags" "redhat.io"

####################################
## pull and dump images

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         part1=$(echo $line | awk  '{split($0,a,"redhat.io"); print a[2]}')
#         part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
#         part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
#         docker tag $line $private_repo$part2:$tag
#         docker push $private_repo$part2:$tag
#         docker tag $line $private_repo$part2
#         docker push $private_repo$part2
#     fi
# done <<< "$ose3_builder_images"

load_redhat_image "$ose3_builder_images" "redhat.io"

####################################
## pull and dump images

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         part1=$(echo $line | awk  '{split($0,a,"redhat.io"); print a[2]}')
#         part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
#         part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
#         docker tag $line $private_repo$part2:$tag
#         docker push $private_repo$part2:$tag
#         docker tag $line $private_repo$part2
#         docker push $private_repo$part2
#     fi
# done <<< "$cnv_optional_imags"

load_redhat_image "$cnv_optional_imags" "redhat.io"

load_redhat_image "$istio_optional_imags" "redhat.io"


##################################
## pull and dump images

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then

#         part2=$(echo $line | awk  '{split($0,a,":"); print a[1]}')
#         part3=$(echo $line | awk  '{split($0,a,":"); print a[2]}')
#         if [ -z "$part3" ]; then
#             docker tag $line $private_repo/$part2
#             docker push $private_repo/$part2
#         else
#             docker tag $line $private_repo/$part2:$part3
#             docker push $private_repo/$part2:$part3
#         fi
#     fi
# done <<< "$docker_builder_images"

load_docker_image "$docker_builder_images"

##################################
## pull and dump images

# while read -r line; do
#     if [[ "$line" =~ [^[:space:]] ]]; then
#         part1=$(echo $line | awk  '{split($0,a,"quay.io"); print a[2]}')
#         part2=$(echo $part1 | awk  '{split($0,a,":"); print a[1]}')
#         part3=$(echo $part1 | awk  '{split($0,a,":"); print a[2]}')
#         if [ -z "$part3" ]; then
#             docker tag $line $private_repo$part2
#             docker push $private_repo$part2
#         else
#             docker tag $line $private_repo$part2:$part3
#             docker push $private_repo$part2:$part3
#         fi
#     fi
# done <<< "$other_builder_images"

load_redhat_image "$other_builder_images" "quay.io"


##################################

docker image prune -f



