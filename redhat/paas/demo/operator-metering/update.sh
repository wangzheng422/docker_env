#!/bin/bash

update_yaml() {

    file=$1
    uri=$2
    
    sed -i "s|{{openshift/oauth-proxy}}|$uri/openshift/oauth-proxy|g" $file

    sed -i "s|{{quay.io/openshift/origin-metering-reporting-operator}}|$uri/openshift/origin-metering-reporting-operator|g" $file

    sed -i "s|{{quay.io/openshift/origin-metering-hive}}|$uri/openshift/origin-metering-hive|g" $file

    sed -i "s|{{quay.io/openshift/origin-metering-presto}}|$uri/openshift/origin-metering-presto|g" $file

    sed -i "s|{{quay.io/openshift/origin-metering-hadoop}}|$uri/openshift/origin-metering-hadoop|g" $file

    sed -i "s|{{quay.io/openshift/origin-metering-helm-operator}}|$uri/openshift/origin-metering-helm-operator|g" $file

}

update_yaml "openshift-metering/values.yaml" "it-registry.redhat.ren:5021"

update_yaml "manifests/deploy/openshift/olm/bundle/4.1/image-references" "it-registry.redhat.ren:5021"

update_yaml "manifests/deploy/openshift/olm/bundle/4.1/meteringoperator.v4.1.0.clusterserviceversion.yaml" "it-registry.redhat.ren:5021"
