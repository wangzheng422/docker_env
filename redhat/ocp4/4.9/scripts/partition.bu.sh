#!/usr/bin/env bash

set -e
set -x

cat << EOF > ./root-partition.bu
variant: openshift
version: 4.8.0
metadata:
  name: root-storage
  labels:
    machineconfiguration.openshift.io/role: worker
storage:
  disks:
    - device: /dev/vda
      wipe_table: false
      partitions:
        - number: 4
          label: root
          size_mib: 204800
          resize: true
EOF

# create 10G partitions
count=5
for var_num in $(seq $count); do

cat << EOF >> ./root-partition.bu
        - label: data_10G_${var_num}
          size_mib: $(( 10 * 1024 ))
EOF

done

# create 5G partitions
count=5
for var_num in $(seq $count); do

cat << EOF >> ./root-partition.bu
        - label: data_5G_${var_num}
          size_mib: $(( 5 * 1024 ))
EOF

done
