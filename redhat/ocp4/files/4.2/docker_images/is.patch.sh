#!/usr/bin/env bash

set -e
# set -x

export LOCAL_REG='registry.redhat.ren'

var_json=$(oc get is -n openshift -l samples.operator.openshift.io/managed=true -o json)

var_i=0
for var_is_name in $(echo $var_json | jq '.items[].metadata.name' ); do
    var_j=0
    for var_is_tag in $(echo $var_json | jq ".items[${var_i}].spec.tags[].name"); do
        var_is_image_name=$(echo $var_json | jq ".items[${var_i}].spec.tags[${var_j}].from.name")
        

        if [[ $var_is_image_name =~ "openshift-release-dev/ocp-v4.0-art-dev" ]]; then
            echo $var_is_name
            echo $var_is_tag
            echo $var_is_image_name

            var_new_image=$(echo $var_is_image_name | sed 's|openshift-release-dev/ocp-v4.0-art-dev|ocp4/openshift4|g')
            echo $var_new_image

            var_is_name_shorten=$(echo ${var_is_name} | sed 's|"||g' )

            set -x
            oc patch -n openshift is ${var_is_name_shorten} -p "{\"spec\":{\"tags\":[{\"name\": $var_is_tag,\"from\":{\"name\":${var_new_image}}}]}}"
            set +x

        fi

        var_j=$((var_j+1))
    done
    var_i=$((var_i+1))
done







