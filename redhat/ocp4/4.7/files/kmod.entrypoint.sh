#!/bin/bash

mkdir /etc/yum.repos.d.bak
mv /etc/yum.repos.d/* /etc/yum.repos.d.bak
cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL-Mirror
baseurl=http://192.168.7.11:8080/dnf/
enabled=1
gpgcheck=0

EOF

dnf clean all -y
dnf makecache

dnf install -y --skip-broken make gcc wget perl createrepo kernel-core-$(uname -r) kernel-devel-$(uname -r) pciutils python36-devel ethtool lsof elfutils-libelf-devel rpm-build kernel-rpm-macros python36 tk numactl-libs libmnl tcl binutils kmod procps git autoconf automake libtool hostname

mkdir -p ~/src/lkm_example
cd ~/src/lkm_example

cat << 'EOF' > lkm_example.c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Wandering Star");
MODULE_DESCRIPTION("A simple example Linux module.");
MODULE_VERSION("0.01");
static int __init lkm_example_init(void) {
 printk(KERN_INFO "Hello, World, Wandering Star!\n");
 return 0;
}
static void __exit lkm_example_exit(void) {
 printk(KERN_INFO "Goodbye, World, Wandering Star!\n");
}
module_init(lkm_example_init);
module_exit(lkm_example_exit);

EOF

cat << EOF > Makefile
obj-m += lkm_example.o
all:
    make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
clean:
    make -C/lib/modules/$(uname -r)/build M=$(pwd) clean
EOF
sed -i 's/^    /\t/g' Makefile

make
insmod lkm_example.ko


