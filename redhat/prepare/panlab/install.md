
```bash

pvcreate -f /dev/sdb
vgextend rhel /dev/sdb
lvremove -f rhel/data

lvcreate -y -L 300G -n data rhel

mkdir -p /mnt/data
mkfs.xfs /dev/rhel/data
mount /dev/rhel/data /mnt/data
mount /dev/nvme/data /data

rsync -P --delete -arz /data/  /mnt/data/

umount /data
umount /mnt/data
rm -rf /mnt/data

mount /dev/rhel/data /data


```