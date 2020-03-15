# google drive upload

https://olivermarshall.net/how-to-upload-a-file-to-google-drive-from-the-command-line/

https://github.com/gdrive-org/gdrive

```bash
############################
## split and merge
split -b 10G registry.tgz registry.
cat registry.?? > registry.tgz

## for cmcc split and merge on osx
split -b 2000m ocp4.tgz ocp4.
split -b 2000m registry.tgz registry.
split -b 2000m rhel-data.tgz rhel-data.


################################
## skicka

yum install -y golang

go get github.com/google/skicka
install /root/go/bin/skicka /usr/local/bin/skicka
skicka init
skicka -no-browser-auth ls

skicka ls "/zhengwan.share/shared_docs/2020.01/ocp.ccn/"
cd /data
mkdir -p /data/upload
/bin/mv -f *.tgz ./upload/
/bin/mv -f registry.* ./upload/
cd /data/upload/

# find ./ -maxdepth 1 -type f -exec skicka upload {}  "/wzh/wangzheng.share/shared_docs/2019.11/ocp 4.2.8/" \;

find ./ -maxdepth 1 -name "*.tgz" -exec skicka upload {}  /"zhengwan.share/shared_docs/2020.01/ocp.ccn/" \;

skicka download "/other.deep.folder/A北区SA资料库/Discovery Session/"

find ./ -maxdepth 1 -name "*.mp4" -exec skicka upload {}  "/zhengwan.share/shared_docs/2020.03/GPTE Advanced Service Mesh/" \;

##################################
## rsync
yum -y install connect-proxy

export VULTR_HOST=nexus.redhat.ren

export VULTR_HOST=base-pvg.redhat.ren

export VULTR_HOST=bastion.1b26.example.opentlc.com

cat << EOF > /root/.ssh/config
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

Host *.redhat.ren 
    ProxyCommand connect-proxy -S 192.168.253.1:5085 %h %p
Host *.opentlc.com 
    ProxyCommand connect-proxy -S 192.168.253.1:5085 %h %p
EOF
# ProxyJump user@bastion-host-nickname
# -J user@bastion-host-nickname

cd /data

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/registry /data/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/ocp4 /data/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/mirror_dir ./

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/remote/4.3.3/is.samples/mirror_dir ./

# sync to base-pvg
rsync -e ssh --info=progress2 -P --delete -arz  /root/data ${VULTR_HOST}:/var/ftp/

rsync -e ssh --info=progress2 -P --delete -arz ./mirror_dir ${VULTR_HOST}:/data/remote/4.3.3/is.samples/


####################
## local mac
# ls -1a *.list

bash
cd /Users/wzh/Desktop/dev/docker_env/redhat/ocp4/files/4.2/image_lists

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

gdrive below
```bash
wget https://github.com/gdrive-org/gdrive/releases/download/2.1.0/gdrive-linux-x64

mv gdrive-linux-x64 gdrive
chmod +x gdrive
install gdrive /usr/local/bin/gdrive

# following the link and give back the code
gdrive list

gdrive upload ***.tgz
```
