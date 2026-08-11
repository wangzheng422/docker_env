#!/usr/bin/env bash

set -e
set -x

# parameter like:
# registry.ocp4.redhat.ren:5443/ocp4/openshift4
parm_local_reg=$1
# export LOCAL_REG='registry.redhat.ren:5443'

var_json=$(oc get is -n openshift -o json | jq -r '.items[] | select( .spec.tags[].from.name | contains( "quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:" ) )' | jq -s .)
# var_json=$(oc get is -n openshift -o json)

var_i=0
for var_is_name in $( jq -r '.[].metadata.name' <<< $var_json ); do
    # echo $var_is_name
    var_j=0
    for var_is_tag in $( jq -r ".[$var_i].spec.tags[].name"  <<< $var_json ); do
        # echo $var_is_tag
        var_is_image_name=$( jq -r ".[$var_i].spec.tags[${var_j}].from.name" <<< $var_json )
        
        var_is_image_kind=$( jq -r ".[$var_i].spec.tags[${var_j}].from.kind" <<< $var_json )
        
        if [[ $var_is_image_kind =~ 'DockerImage'  ]]; then

            if [[ $var_is_image_name == 'quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:'* ]]; then

                var_new_is_image_name=$(echo $var_is_image_name | sed "s|quay.io/openshift-release-dev/ocp-v4.0-art-dev|${parm_local_reg}|g")

                echo "############################### ocp-v4.0-art-dev@sha256"
                echo $var_is_name
                echo $var_is_tag
                echo $var_is_image_name
                echo $var_is_image_kind

                echo $var_new_is_image_name

                oc patch -n openshift is ${var_is_name} --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/tags/${var_j}/from/name\", \"value\":\"${var_new_is_image_name}\"}]"

                sleep 1

            fi

        fi

        var_j=$((var_j+1))
    done

    sleep 10
    oc import-image --all $var_is_name -n openshift

    var_i=$((var_i+1))
done







