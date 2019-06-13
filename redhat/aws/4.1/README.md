# 4.1

```bash
mkdir -p conf

vi conf/install-config.yaml 

./openshift-install create install-config --dir=conf/

./openshift-install create manifests --dir=conf/

rm -f conf/openshift/99_openshift-cluster-api_master-machines-*.yaml
rm -f conf/openshift/99_openshift-cluster-api_worker-machineset-*

./openshift-install create ignition-configs --dir=conf/

aws s3 mb s3://ocp41demo-infra

ls conf/

aws s3 cp conf/bootstrap.ign s3://ocp41demo-infra/bootstrap.ign
aws s3 cp conf/master.ign s3://ocp41demo-infra/master.ign
aws s3 cp conf/worker.ign s3://ocp41demo-infra/worker.ign

aws s3 ls s3://ocp41demo-infra/

./openshift-install wait-for bootstrap-complete --dir=conf  --log-level debug


```

us-west-1 ami-0e52dafdb6762af40

















## no use

```bash

scp bootstrap.ign core@aws4boot.redhat.ren:~/
ssh core@aws4boot.redhat.ren
coreos-install -d /dev/nvme1n1 -i /home/core/bootstrap.ign

wget 192.168.253.1:8000/1.gz
wget 192.168.253.1:8000/1.ova
wget 192.168.253.1:8000/bootstrap.ign
coreos-install -d /dev/sda -f 1.ova -i bootstrap.ign -o vmware-raw
```

https://stable.release.core-os.net/amd64-usr/2079.5.1/coreos_production_ami_image.bin.bz2

core@ip-172-31-17-71 ~ $ coreos-install /dev/nvme0n1 -i ./bootstrap.ign
/usr/bin/coreos-install: No target block device provided, -d is required.
    -d DEVICE   Install Container Linux to the given device.
    -V VERSION  Version to install (e.g. current) [default: 2079.5.1].
    -B BOARD    Container Linux board to use [default: amd64-usr].
    -C CHANNEL  Release channel to use (e.g. beta) [default: stable].
    -o OEM      OEM type to install (e.g. ami) [default: ami].
    -c CLOUD    Insert a cloud-init config to be executed on boot.
    -i IGNITION Insert an Ignition config to be executed on boot.
    -b BASEURL  URL to the image mirror (overrides BOARD).
    -k KEYFILE  Override default GPG key for verifying image signature.
    -f IMAGE    Install unverified local image file to disk instead of fetching.
    -n          Copy generated network units to the root partition.
    -y          Dry-run.  Run some checks and print option settings.
    -v          Super verbose, for debugging.
    -h          This ;-).

This tool installs CoreOS Container Linux on a block device. If you PXE booted
Container Linux on a machine then use this tool to make a permanent install.

ami-0e52dafdb6762af40