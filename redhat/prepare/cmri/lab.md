# 

```bash

yum install icedtea-web

# to crmi
rsync -e ssh --info=progress2 -P --delete -arz  /root/data root@172.29.159.3:/home/wzh/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz  /data/ocp4 root@172.29.159.3:/home/wzh/ocp4

rsync -e ssh --info=progress2 -P --delete -arz  /data/registry/  root@172.29.159.3:/home/wzh/registry/

rsync -e ssh --info=progress2 -P --delete -arz  /data/is.samples root@172.29.159.3:/home/wzh/is.samples

```