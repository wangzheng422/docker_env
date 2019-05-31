#

ansible能不能搞 N 层嵌套的host group.

https://github.com/ansible/ansible/tree/devel/contrib/inventory

```bash
ansible-doc -l


```

```bash
useradd devops

echo 'r3dh4t1!' | passwd --stdin devops

su - devops

ssh-keygen -N '' -f ~/.ssh/id_rsa

ansible all -m user -a "name=devops"

ansible all -m authorized_key -a "user=devops state=present key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5reyHNs28s3u9DlV31e2K7mPhsCnPTFj+zg4jVUV3NheDbQQu44q/mAH+ezCasi0dRelT6nFVFpyJqzx84M7SOBrfF/vH4IUTjWj3Zsk1mYWiCFriYW3gSN9USXong9eJoNO4pttrhBuVHVjhzQi4s7GF5rsCzxwJh+YxuUgemo+/4LPwX2202mF8k4Dj3gcHw0KVmnvHTFe3HEribQs5xCu5x7kaj4/Q4lMfIDrzz9L8UEXra0qBoqz8msxlEgn6aFB+PGxSW5wScxYGejtLx9Qt5hZUGtTEqBSczzsN3/sOvOPenkhx+B71VomRF66X+hFDXMpWrMr0HF18Iz3v devops@bastion.9d83.example.opentlc.com'"

ansible all -m lineinfile -a "dest=/etc/sudoers state=present line='devops ALL=(ALL) NOPASSWD: ALL'"

export GUID=`hostname | awk -F"." '{print $2}'`

ansible localhost -m command -a 'id'
```