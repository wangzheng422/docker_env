# osp

```bash
virt-customize --selinux-relabel -a overcloud-full.qcow2 --root-password 

virt-customize --selinux-relabel -a overcloud-full.qcow2 --run-command 'subscription-manager register --username=[username] --password=[password]'

virt-customize --selinux-relabel -a overcloud-full.qcow2 --run-command 'subscription-manager attach --pool [subscription-pool]'

virt-customize --selinux-relabel -a overcloud-full.qcow2 --upload opendaylight.repo:/etc/yum.repos.d/

virt-customize --selinux-relabel -a overcloud-full.qcow2 --install opendaylight

virt-customize --selinux-relabel -a overcloud-full.qcow2 --run-command 'subscription-manager remove --all'

virt-customize --selinux-relabel -a overcloud-full.qcow2 --run-command 'subscription-manager unregister'

virt-sysprep --operation machine-id -a overcloud-full.qcow2

```