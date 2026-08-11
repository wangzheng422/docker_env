#!/usr/bin/sh

mkdir -p /exports/pv{1..40}

for pvnum in {1..40} ; do
echo "/exports/pv${pvnum} *(rw,root_squash)" >> /etc/exports.d/openshift-uservols.exports
chown -R nfsnobody.nfsnobody  /srv/nfs/user-vols/pv${pvnum}
chmod -R 777 /srv/nfs
done

systemctl restart nfs-server
