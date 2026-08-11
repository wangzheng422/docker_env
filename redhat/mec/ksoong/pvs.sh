#!/usr/bin/sh

export NFS_SERVER="it-lb.redhat.ren"

#######################
# 5Gi - ReadWriteOnce #
#######################
export volsize="5Gi"
mkdir /root/pvs
for volume in pv{1..10} ; do
cat << EOF > /root/pvs/${volume}.yml
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteOnce" ],
    "nfs": {
        "path": "/exports/${volume}",
        "server": "${NFS_SERVER}"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
echo "Created def file for ${volume}.yml";
done;

#######################
# 5Gi - ReadWriteMany #
#######################
export volsize="5Gi"
for volume in pv{11..20} ; do
cat << EOF > /root/pvs/${volume}.yml
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteMany" ],
    "nfs": {
        "path": "/exports/${volume}",
        "server": "${NFS_SERVER}"
    },
    "persistentVolumeReclaimPolicy": "Retain"
  }
}
EOF
echo "Created def file for ${volume}.yml";
done;

#######################
# 10Gi - ReadWriteOnce #
#######################
export volsize="50Gi"
for volume in pv{21..30} ; do
cat << EOF > /root/pvs/${volume}.yml
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteOnce" ],
    "nfs": {
        "path": "/exports/${volume}",
        "server": "${NFS_SERVER}"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
echo "Created def file for ${volume}.yml";
done;

#######################
# 10Gi - ReadWriteMany #
#######################
export volsize="50Gi"
for volume in pv{31..40} ; do
cat << EOF > /root/pvs/${volume}.yml
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteMany" ],
    "nfs": {
        "path": "/exports/${volume}",
        "server": "${NFS_SERVER}"
    },
    "persistentVolumeReclaimPolicy": "Retain"
  }
}
EOF
echo "Created def file for ${volume}.yml";
done;
