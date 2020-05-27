```bash
cat << EOF > ~/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

EOF

# in .zshrc
# alias ssh="ssh -F ~/.ssh/config"

# vm
# https://access.redhat.com/solutions/4009
pvcreate /dev/sdb 
vgextend rhel /dev/sdb

vgdisplay rhel | egrep 'PE Size|Free  PE'
lvextend -l 100%VG /dev/rhel/root
# lvextend -l 100%VG /dev/rhel/root -r
xfs_growfs /dev/rhel/root

```