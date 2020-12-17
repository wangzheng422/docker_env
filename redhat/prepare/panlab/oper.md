```bash

podman start local-registry

systemctl start vncserver@:1

# setup ftp data root
mount --bind /data/dnf /var/ftp/dnf
chcon -R -t public_content_t  /var/ftp/dnf

ps -ef | grep vbmcd | awk '{print $2}' | xargs kill
/bin/rm -f /root/.vbmc/master.pid
/root/.local/bin/vbmcd

/root/.local/bin/sushy-emulator -i 0.0.0.0 --ssl-certificate /etc/crts/redhat.ren.crt --ssl-key /etc/crts/redhat.ren.key

virsh start ocp4-aHelper
virsh start ocp4-master0 
virsh start ocp4-master1 
virsh start ocp4-master2 
virsh start ocp4-worker0 
virsh start ocp4-worker1 
virsh start ocp4-worker2

```