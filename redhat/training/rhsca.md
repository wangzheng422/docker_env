# RHCSA

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/selinux_users_and_administrators_guide/index#sect-Security-Enhanced_Linux-Fixing_Problems-Allowing_Access_audit2allow

https://people.redhat.com/duffy/selinux/selinux-coloring-book_A4-Stapled.pdf



```bash
export LANG=$i

localectl set-locale LANG=fr_FR.utf8

yum list langpacks-*

yum install langpacks-fr

yum repoquery --whatsupplements langpacks-fr

ssh-keygen -f .ssh/key-with-pass

eval $(ssh-agent)

ssh-add

ssh-copy-id

sudo systemctl status cockpit.socket

redhat-support-tool

```