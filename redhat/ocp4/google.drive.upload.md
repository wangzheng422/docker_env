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

export VULTR_HOST=zero.pvg.redhat.ren

export VULTR_HOST=vcdn.redhat.ren

export VULTR_HOST=bastion.ef34.example.opentlc.com

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

# sync from aws to localvm
cd /data

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/ocp4/ /data/ocp4/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/registry/ /data/registry/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/install.image/ /data/install.image/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/poc.image/ /data/poc.image/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/redhat-operator/ /data/redhat-operator/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/certified-operator/ /data/certified-operator/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/community-operator/ /data/community-operator/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/is.samples/ /data/is.samples/

## sync from aws to pvg
cd /data/remote/4.4.7

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/ocp4 ./

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/registry /data/

# copy to local disk
# localvm.md

var_version='4.6.12-gpu'
mkdir -p /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/

cd /root
tar -cvf - data/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/rhel-data-7.9.tgz

cd /data
tar -cvf - ocp4/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/ocp4.tgz
tar -cvf - registry/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/registry.tgz
tar -cvf - poc.image/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/poc.image.tgz

cd /data/ccn
tar -cvf - nexus-image/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/nexus-image.tgz


tar -cvf - install.image/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/install.image.tgz
tar -cvf - redhat-operator/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/redhat-operator.tgz
tar -cvf - certified-operator/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/certified-operator.tgz
tar -cvf - community-operator/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/community-operatorn.tgz
tar -cvf - is.samples/ | pigz -c > /mnt/hgfs/ocp.archive/ocp.tgz.$var_version/is.samples.tgz

# on osx split the files
cd /Volumes/Mac2T/ocp.archive/ocp.tgz.4.6.9-ccn
split -b 20000m nexus-image.tgz nexus-image.tgz.

split -b 20000m rhel-data-7.9.tgz rhel-data-7.9.
split -b 20000m redhat-operator.tgz redhat-operator.tgz.
split -b 20000m is.samples.tgz is.samples.tgz.

# sync to base-pvg
rsync -e ssh --info=progress2 -P --delete -arz  /root/data ${VULTR_HOST}:/var/ftp/

rsync -e ssh --info=progress2 -P --delete -arz ./mirror_dir ${VULTR_HOST}:/data/remote/4.3.3/is.samples/

# sync from base-pvg
export VULTR_HOST=zero.pvg.redhat.ren

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/var/ftp/data /root/

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/remote/4.3.3/is.samples/mirror_dir ./

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/remote/4.3.21/ocp4 ./

rsync -e ssh --info=progress2 -P --delete -arz ${VULTR_HOST}:/data/remote/4.3.21/registry ./

split -b 5000m ocp.4.3.21.tgz ocp.4.3.21.
split -b 5000m registry.4.3.21.tgz registry.4.3.21.
split -b 5000m rhel-data-7.8.tgz rhel-data-7.8.

# sync to vcdn.redhat.ren
rsync -e ssh --info=progress2 -P --delete -arz  /root/data ${VULTR_HOST}:/data/rhel-data

rsync -e ssh --info=progress2 -P --delete -arz /data/registry ${VULTR_HOST}:/data/

rsync -e ssh --info=progress2 -P --delete -arz /data/ocp4 ${VULTR_HOST}:/data/

rsync -e ssh --info=progress2 -P --delete -arz /data/is.samples ${VULTR_HOST}:/data/

# upload to pan lab
rsync -e ssh --info=progress2 -P --delete -arz /data/ocp4/ ocp.pan.redhat.ren:/data/ocp4/

rsync -e ssh --info=progress2 -P --delete -arz /data/registry/ ocp.pan.redhat.ren:/data/registry/

rsync -e ssh --info=progress2 -P --delete -arz /data/install.image/ ocp.pan.redhat.ren:/data/install.image/

# download from pan lab
mkdir -p /data/ccn/nexus-image
rsync -e ssh --info=progress2 -P --delete -arz ocp.pan.redhat.ren:/data/ccn/nexus-image/  /data/ccn/nexus-image/

# upload to cmcc lab
rsync -e ssh --info=progress2 -P --delete -arz /data/ocp4/ 172.29.159.3:/home/wzh/4.6.16/ocp4/

#######################################
# baidu pan on rhel8
mkdir -p tmp
mv rhel8.dnf.tgz.* tmp/

# https://github.com/houtianze/bypy
yum -y install python3-pip
pip3 install --user bypy 
/root/.local/bin/bypy list
/root/.local/bin/bypy upload

/root/.local/bin/bypy download

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
