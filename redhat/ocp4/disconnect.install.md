https://blog.openshift.com/openshift-4-2-disconnected-install/

https://blog.openshift.com/openshift-4-bare-metal-install-quickstart/

https://github.com/christianh814/ocp4-upi-helpernode#ocp4-upi-helper-node-playbook

```bash
yum -y install podman 

mkdir /etc/crts/ && cd /etc/crts
openssl req \
   -newkey rsa:2048 -nodes -keyout redhat.ren.key \
   -x509 -days 3650 -out redhat.ren.crt -subj \
   "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.redhat.ren"

cp /etc/crts/redhat.ren.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

mkdir -p /etc/docker/certs.d/redhat.ren
cp -f /etc/crts/redhat.ren.crt /etc/docker/certs.d/redhat.ren

systemctl restart docker
systemctl restart docker-distribution

export BUILDNUMBER=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Name:' | awk '{print $NF}')
echo ${BUILDNUMBER}

export http_proxy=http://192.168.253.1:5084
export https_proxy=http://192.168.253.1:5084

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/openshift-client-linux-${BUILDNUMBER}.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/openshift-install-linux-${BUILDNUMBER}.tar.gz

tar -xzf openshift-client-linux-${BUILDNUMBER}.tar.gz -C /usr/local/bin/
tar -xzf openshift-install-linux-${BUILDNUMBER}.tar.gz -C /usr/local/bin/

# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest/rhcos-${BUILDNUMBER}-metal-bios.raw.gz
# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest/rhcos-${BUILDNUMBER}-installer-initramfs.imghtml/
# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest/rhcos-${BUILDNUMBER}-installer-kernel

# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest/rhcos-${BUILDNUMBER}-metal-bios.raw.gz
# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest/rhcos-${BUILDNUMBER}-installer.iso

wget --recursive --no-directories --no-parent https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest/


export OCP_RELEASE="4.2.0-0.nightly-2019-10-07-203748"
export LOCAL_REG='vm.redhat.ren'
export LOCAL_REPO='ocp4/openshift4'
export UPSTREAM_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="pull-secret.json"
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
export RELEASE_NAME="ocp-release-nightly"


oc adm release mirror -a ${LOCAL_SECRET_JSON} \
--from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
--to-release-image=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE} \
--to=${LOCAL_REG}/${LOCAL_REPO}

```
output of mirror of images
```
Success
Update image:  vm.redhat.ren/ocp4/openshift4:4.2.0-0.nightly-2019-10-07-203748
Mirror prefix: vm.redhat.ren/ocp4/openshift4

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - vm.redhat.ren/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release-nightly
- mirrors:
  - vm.redhat.ren/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - vm.redhat.ren/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release-nightly
  - mirrors:
    - vm.redhat.ren/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
```

```bash
openshift-install create ignition-configs --dir=/root/ocp4
```

