#!/usr/bin/env bash

set -e
set -x

export LOCAL_REG='registry.redhat.ren:5443'

var_json=$(oc get is -n openshift -l samples.operator.openshift.io/managed=true -o json)
# var_json=$(oc get is -n openshift -o json)

var_i=0
for var_is_name in $( jq -r '.items[].metadata.name' <<< $var_json ); do
    var_j=0
    for var_is_tag in $( jq -r ".items[${var_i}].spec.tags[].name"  <<< $var_json ); do

        var_is_image_name=$( jq -r ".items[${var_i}].spec.tags[${var_j}].from.name" <<< $var_json )
        
        var_is_image_kind=$( jq -r ".items[${var_i}].spec.tags[${var_j}].from.kind" <<< $var_json )
        
        if [[ $var_is_image_kind =~ 'DockerImage'  ]]; then

            if [[ $var_is_image_name == "${LOCAL_REG}"* ]]; then
                echo "already localization..."
            elif [[ $var_is_image_name == 'quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:'* ]]; then

                var_new_is_image_name=$(echo $var_is_image_name | sed "s|quay.io/openshift-release-dev/ocp-v4.0-art-dev|${LOCAL_REG}/ocp4/openshift4|g")

                echo "############################### ocp-v4.0-art-dev@sha256"
                echo $var_is_name
                echo $var_is_tag
                echo $var_is_image_name
                echo $var_is_image_kind

                echo $var_new_is_image_name

                # set -x

                oc patch -n openshift is ${var_is_name} --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/tags/${var_j}/from/name\", \"value\":\"${var_new_is_image_name}\"}]"

                # set +x

            elif [[ $var_is_image_name =~ ^.*\.(io|com|org)/.* ]]; then

                var_new_is_image_name="${LOCAL_REG}/$var_is_image_name"
                
                echo "###############################"
                echo $var_is_name
                echo $var_is_tag
                echo $var_is_image_name
                echo $var_is_image_kind

                echo $var_new_is_image_name

                # set -x

                oc patch -n openshift is ${var_is_name} --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/tags/${var_j}/from/name\", \"value\":\"${var_new_is_image_name}\"}]"

                # oc patch -n openshift is ${var_is_name} -p "{\"spec\":{\"tags\" : [ { \"name\" : \"$var_is_tag\", \"from\" :{\"name\" : \"${var_new_is_image_name}\" , \"kind\" : \"DockerImage\" } } ] } }" --type=merge 

                # set +x
            fi

        fi

        var_j=$((var_j+1))
    done

    sleep 10
    oc import-image --all $var_is_name -n openshift

    var_i=$((var_i+1))
done







