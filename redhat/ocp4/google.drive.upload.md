# google drive upload

https://olivermarshall.net/how-to-upload-a-file-to-google-drive-from-the-command-line/

https://github.com/gdrive-org/gdrive

```bash

################################
## skicka

yum install -y golang

go get github.com/google/skicka
install /root/go/bin/skicka /usr/local/bin/skicka
skicka init
skicka -no-browser-auth ls
skicka ls "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.4/"
cd /data
skicka upload ./ocp4.tgz  "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.4/"
skicka upload ./registry.tgz  "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.4/"

##################################
## rsync
yum -y install connect-proxy

cat << EOF > /root/.ssh/config
Host 45.32.85.251
    ProxyCommand connect-proxy -S 192.168.253.1:5085 %h %p
EOF

rsync -e ssh --progress --delete -arz 45.32.85.251:/data/registry /data/

rsync -e ssh --progress --delete -arz 45.32.85.251:/data/ocp4 /data/

```

no use below
```bash
wget https://github.com/gdrive-org/gdrive/releases/download/2.1.0/gdrive-linux-x64

mv gdrive-linux-x64 gdrive
chmod +x gdrive
install gdrive /usr/local/bin/gdrive

# following the link and give back the code
gdrive list

gdrive upload ***.tgz
```
