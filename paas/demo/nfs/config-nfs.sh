#!/usr/bin/sh

mkdir -p /exports/pv{1..40}

for pvnum in {1..40} ; do
echo "/exports/pv${pvnum} *(rw,root_squash)" >> /etc/exports.d/openshift-uservols.exports
chown -R nfsnobody.nfsnobody  /exports/pv${pvnum}
chmod -R 777 /exports/pv${pvnum}
done

systemctl restart nfs-server
