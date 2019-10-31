#!/usr/bin/env bash

set -e
set -x

cat << EOF > image.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: operator-images
spec:
  repositoryDigestMirrors:
EOF

while read -r line; do

    if [[ $line =~ ^.*\.(io|com|org)/.*:.* ]]; then
        echo "io, com, org with tag: $line"
    elif [[ $line =~ ^.*\.(io|com|org)/[^:]*  ]]; then
        echo "io, com, org without tag: $line"
    elif [[ $line =~ ^.*/.*:.* ]]; then
        echo "docker with tag: $line"
    elif [[ $line =~ ^.*/[^:]* ]]; then
        echo "docker without tag: $line"
    fi

done < image.list