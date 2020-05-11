# RHCSA

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