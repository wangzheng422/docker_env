# odf lost a disk analyze

ODF安装的时候，发现少了一个硬盘

https://access.redhat.com/articles/4870821

```bash

oc rsh -n openshift-storage $(oc get pods -n openshift-storage -o name -l app=rook-ceph-operator)

export CEPH_ARGS='-c /var/lib/rook/openshift-storage/openshift-storage.config'

ceph osd tree
# ID  CLASS  WEIGHT   TYPE NAME                     STATUS  REWEIGHT  PRI-AFF
# -1         2.18346  root default
# -7         0.87338      host master1-ocp-ytl-com
#  2    ssd  0.43669          osd.2                     up   1.00000  1.00000
#  3    ssd  0.43669          osd.3                     up   1.00000  1.00000
# -3         0.87338      host master2-ocp-ytl-com
#  0    ssd  0.43669          osd.0                     up   1.00000  1.00000
#  1    ssd  0.43669          osd.1                     up   1.00000  1.00000
# -5         0.43669      host master3-ocp-ytl-com
#  4    ssd  0.43669          osd.4                     up   1.00000  1.00000

```

local storage operator是好的，也发现了硬盘。然后找了半天，最后查到了一个log，大概的原因，是硬盘上面有分区，所以ceph在格式化硬盘的时候，出现错误，就放弃那个硬盘了。

```bash

pwd
# /var/lib/rook/openshift-storage

ls -l
# total 12
# -rw-------. 1 root root  152 Dec 13 11:28 client.admin.keyring
# drwxr-xr-x. 3  167  167   28 Dec  7 14:32 crash
# drwxr-xr-x. 4  167  167 4096 Dec 15 00:11 log
# drwxr-xr-x. 3 root root   28 Dec  7 14:33 ocs-deviceset-local-volume-set-0-data-14dhbv
# -rw-r--r--. 1 root root  739 Dec 13 11:28 openshift-storage.config

cd logs

ls -hl
# total 91M
# -rw-r--r--. 1 167 167  2.7M Dec 13 06:55 ceph-client.rgw.ocs.storagecluster.cephobjectstore.a.log
# -rw-r--r--. 1 167 167  462K Dec 13 00:09 ceph-client.rgw.ocs.storagecluster.cephobjectstore.a.log.1.gz
# -rw-r--r--. 1 167 167  241K Dec  8 00:05 ceph-client.rgw.ocs.storagecluster.cephobjectstore.a.log.2.gz
# -rw-r--r--. 1 167 167  499K Dec 12 10:35 ceph-mds.ocs-storagecluster-cephfilesystem-a.log
# -rw-r--r--. 1 167 167  356K Dec 13 06:55 ceph-mds.ocs-storagecluster-cephfilesystem-b.log
# -rw-r--r--. 1 167 167  152K Dec 13 00:09 ceph-mds.ocs-storagecluster-cephfilesystem-b.log.1.gz
# -rw-r--r--. 1 167 167   16K Dec  8 00:05 ceph-mds.ocs-storagecluster-cephfilesystem-b.log.2.gz
# -rw-r--r--. 1 167 167  9.5M Dec 12 10:35 ceph-mgr.a.log
# -rw-r--r--. 1 167 167  9.0M Dec  8 12:33 ceph-mon.c.log
# -rw-r--r--. 1 167 167  346K Dec  8 00:02 ceph-mon.c.log.1.gz
# -rw-r--r--. 1 167 167  2.7M Dec 15 05:08 ceph-mon.e.log
# -rw-r--r--. 1 167 167  897K Dec 15 00:11 ceph-mon.e.log.1.gz
# -rw-r--r--. 1 167 167  992K Dec 14 00:11 ceph-mon.e.log.2.gz
# -rw-r--r--. 1 167 167 1008K Dec 13 00:00 ceph-mon.e.log.3.gz
# -rw-r--r--. 1 167 167  875K Dec 12 00:05 ceph-mon.e.log.4.gz
# -rw-r--r--. 1 167 167  827K Dec 11 00:00 ceph-mon.e.log.5.gz
# -rw-r--r--. 1 167 167  1.3M Dec 10 00:10 ceph-mon.e.log.6.gz
# -rw-r--r--. 1 167 167  418K Dec  9 00:07 ceph-mon.e.log.7.gz
# -rw-r--r--. 1 167 167  1.8M Dec 15 05:02 ceph-osd.4.log
# -rw-r--r--. 1 167 167  143K Dec 15 00:02 ceph-osd.4.log.1.gz
# -rw-r--r--. 1 167 167  9.1M Dec 14 00:07 ceph-osd.4.log.2.gz
# -rw-r--r--. 1 167 167   27M Dec 13 10:08 ceph-osd.4.log.3.gz
# -rw-r--r--. 1 167 167  1.2M Dec 13 00:09 ceph-osd.4.log.4.gz
# -rw-r--r--. 1 167 167  869K Dec 12 00:03 ceph-osd.4.log.5.gz
# -rw-r--r--. 1 167 167  822K Dec 11 00:01 ceph-osd.4.log.6.gz
# -rw-r--r--. 1 167 167   18M Dec 10 00:08 ceph-osd.4.log.7.gz
# drwxr-x---. 2 167 167    37 Dec  7 14:33 ocs-deviceset-local-volume-set-0-data-14dhbv
# drwxr-x---. 2 167 167    37 Dec  7 14:33 ocs-deviceset-local-volume-set-0-data-4tfgts


cd ocs-deviceset-local-volume-set-0-data-4tfgts

ls -hl
# total 1.2M
# -rw-r--r--. 1 167 167 1.2M Dec 13 11:25 ceph-volume.log



cat ceph-volume.log
# ......
# [2022-12-13 11:25:49,479][ceph_volume.main][INFO  ] Running command: ceph-volume --log-path /var/log/ceph/ocs-deviceset-local-volume-set-0-data-4tfgts raw prepare --bluestore --data /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts
# [2022-12-13 11:25:49,480][ceph_volume.process][INFO  ] Running command: /usr/bin/lsblk -plno KNAME,NAME,TYPE
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/loop0 /dev/loop0 loop
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/loop1 /dev/loop1 loop
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/sda   /dev/sda   disk
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/sda1  /dev/sda1  part
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/sda2  /dev/sda2  part
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/sda3  /dev/sda3  part
# [2022-12-13 11:25:49,486][ceph_volume.process][INFO  ] stdout /dev/sda4  /dev/sda4  part
# [2022-12-13 11:25:49,487][ceph_volume.process][INFO  ] stdout /dev/sdb   /dev/sdb   disk
# [2022-12-13 11:25:49,487][ceph_volume.process][INFO  ] stdout /dev/sdc   /dev/sdc   disk
# [2022-12-13 11:25:49,492][ceph_volume.process][INFO  ] Running command: /usr/sbin/lvs --noheadings --readonly --separator=";" -a --units=b --nosuffix -S lv_path=/mnt/ocs-deviceset-local-volume-set-0-data-4tfgts -o lv_tags,lv_path,lv_name,vg_name,lv_uuid,lv_size
# [2022-12-13 11:25:49,659][ceph_volume.process][INFO  ] Running command: /usr/bin/lsblk --nodeps -P -o NAME,KNAME,MAJ:MIN,FSTYPE,MOUNTPOINT,LABEL,UUID,RO,RM,MODEL,SIZE,STATE,OWNER,GROUP,MODE,ALIGNMENT,PHY-SEC,LOG-SEC,ROTA,SCHED,TYPE,DISC-ALN,DISC-GRAN,DISC-MAX,DISC-ZERO,PKNAME,PARTLABEL /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts
# [2022-12-13 11:25:49,664][ceph_volume.process][INFO  ] stdout NAME="sdb" KNAME="sdb" MAJ:MIN="8:16" FSTYPE="" MOUNTPOINT="" LABEL="" UUID="" RO="0" RM="1" MODEL="SAMSUNG MZ7LH480" SIZE="447.1G" STATE="running" OWNER="root" GROUP="disk" MODE="brw-rw----" ALIGNMENT="0" PHY-SEC="4096" LOG-SEC="512" ROTA="0" SCHED="mq-deadline" TYPE="disk" DISC-ALN="0" DISC-GRAN="4K" DISC-MAX="2G" DISC-ZERO="0" PKNAME="" PARTLABEL=""
# [2022-12-13 11:25:49,665][ceph_volume.process][INFO  ] Running command: /usr/sbin/blkid -c /dev/null -p /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts
# [2022-12-13 11:25:49,669][ceph_volume.process][INFO  ] stdout /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts: PTUUID="6fe29d49-b979-4839-ba6c-0cd8ee29dd8f" PTTYPE="gpt"[2022-12-13 11:25:49,669][ceph_volume.process][INFO  ] Running command: /usr/sbin/pvs --noheadings --readonly --units=b --nosuffix --separator=";" -o vg_name,pv_count,lv_count,vg_attr,vg_extent_count,vg_free_count,vg_extent_size /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts
# [2022-12-13 11:25:49,764][ceph_volume.process][INFO  ] stderr Cannot use /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts: device is partitioned
# [2022-12-13 11:25:49,765][ceph_volume.util.disk][INFO  ] opening device /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts to check for BlueStore label
# [2022-12-13 11:25:49,765][ceph_volume.util.disk][INFO  ] opening device /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts to check for BlueStore label
# [2022-12-13 11:25:49,765][ceph_volume.process][INFO  ] Running command: /usr/sbin/udevadm info --query=property /mnt/ocs-deviceset-local-volume-set-0-data-4tfgts
# [2022-12-13 11:25:49,773][ceph_volume.process][INFO  ] stderr Unknown device, --name=, --path=, or absolute path in /dev/ or /sys expected.


```