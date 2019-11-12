# google drive upload

https://olivermarshall.net/how-to-upload-a-file-to-google-drive-from-the-command-line/

https://github.com/gdrive-org/gdrive

```bash

wget https://github.com/gdrive-org/gdrive/releases/download/2.1.0/gdrive-linux-x64

mv gdrive-linux-x64 gdrive
chmod +x gdrive
install gdrive /usr/local/bin/gdrive

# following the link and give back the code
gdrive list

gdrive upload ***.tgz

go get github.com/google/skicka
install skicka /usr/local/bin/skicka
skicka init
skicka -no-browser-auth ls
skicka ls "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.2/"
skicka upload ./ocp4.tgz  "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.2/"
skicka upload ./registry.tgz  "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.2/"


rsync --progress --delete -arz 149.28.95.3:/data/registry /data/

rsync --progress --delete -arz 149.28.95.3:/data/ocp4 /data/

```

