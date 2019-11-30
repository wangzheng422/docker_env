# google drive upload

https://olivermarshall.net/how-to-upload-a-file-to-google-drive-from-the-command-line/

https://github.com/gdrive-org/gdrive

```bash
############################
## split and merge
split -b 10G registry.tgz registry.
cat registry.?? > registry.tgz

################################
## skicka

yum install -y golang

go get github.com/google/skicka
install /root/go/bin/skicka /usr/local/bin/skicka
skicka init
skicka -no-browser-auth ls
skicka ls "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.8/"
cd /data
mkdir -p /data/upload
/bin/mv -f *.tgz ./upload/
/bin/mv -f registry.* ./upload/
cd /data/upload/

find ./ -maxdepth 1 -type f -exec skicka upload {}  "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.8/" \;

##################################
## rsync
yum -y install connect-proxy

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

Host 66.42.96.69
    ProxyCommand connect-proxy -S 192.168.253.1:5085 %h %p
EOF

cd /data

rsync -e ssh --progress --delete -arz 66.42.96.69:/data/registry /data/

rsync -e ssh --progress --delete -arz 66.42.96.69:/data/ocp4 /data/

####################
## local mac
# ls -1a *.list
var_files=$(cat << EOF
operator.failed.list
operator.image.list
operator.ok.list
pull.image.failed.list
pull.image.ok.list
pull.sample.image.failed.list
pull.sample.image.ok.list
yaml.image.ok.list
yaml.sample.image.ok.list
install.image.list.tmp.uniq
yaml.image.ok.list.uniq
EOF
)

while read -r line; do
    scp root@192.168.253.11:/data/ocp4/${line} ./
done <<< "$var_files"

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
