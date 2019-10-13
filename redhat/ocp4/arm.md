# 参考资料

https://adam.younglogic.com/2017/08/openshift-origin-from-source/

https://github.com/Project31/ansible-kubernetes-openshift-pi3

```bash
yum groupinstall "Development Tools"

yum -y install git docker

yum -y install golang make gcc zip mercurial krb5-devel bsdtar bc rsync bind-utils file jq tito createrepo openssl gpgme gpgme-devel libassuan libassuan-devel

systemctl start docker

# https://github.com/openshift/origin/blob/master/CONTRIBUTING.adoc#download-from-github
mkdir $HOME/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export OS_OUTPUT_GOPATH=1

mkdir -p $GOPATH/src/github.com/openshift
cd $GOPATH/src/github.com/openshift

git clone https://github.com/openshift/origin
cd origin 
git checkout release-3.11


vi hack/build-cross.sh
# platforms=(
#   linux/arm64
# )

# hack/env make

# hack/env make build-cross

# OS_ONLY_BUILD_PLATFORMS='linux/amd64'
hack/env make release

# hack/env  OS_ONLY_BUILD_PLATFORMS='linux/arm64' make release

vi hack/lib/init.sh
set -o xtrace

docker rm -fv $(docker ps -qa)
docker volume prune -f
docker image rm -f $(docker image ls -qa)

# atomic-openshift
yum install yum-utils
yumdownloader --source atomic-openshift

# subscription-manager repos --enable=rhel-7-server-ose-3.11-source-rpms
# subscription-manager repos --disable=rhel-7-server-ose-3.11-source-rpms
reposync -n -d -l -m --source -r rhel-7-server-ose-3.11-source-rpms
cp rhel-7-server-ose-3.11-source-rpms/Packages/a/atomic-openshift-3.11.146-1.git.0.4aab273.el7.src.rpm ./

yum -y install rpm-build redhat-rpm-config gcc make
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
# rpmbuild --rebuild ./atomic-openshift-3.11.146-1.git.0.4aab273.el7.src.rpm

# https://www.golinuxcloud.com/steps-rebuild-rpm-source-rpm-rhel-7-linux/
yum -y install rpmdevtools
rpmdev-setuptree

yum -y install git docker
yum -y install golang make gcc zip mercurial krb5-devel bsdtar bc rsync bind-utils file jq tito createrepo openssl gpgme gpgme-devel libassuan libassuan-devel
yum -y install vim goversioninfo bsdtar golang krb5-devel

cp atomic-openshift-3.11.146-1.git.0.4aab273.el7.src.rpm ~/down
rpm2cpio atomic-openshift-3.11.146-1.git.0.4aab273.el7.src.rpm | cpio -idm
tar zxf atomic-openshift-git-0.4aab273.tar.gz

cd /root/down
# mv atomic-openshift-git-0.4aab273 atomic-openshift-3.11.146
# patch pkg/apps/apiserver/registry/deployconf/etcd/etcd.go
# common out //"k8s.io/kubernetes/staging/src/k8s.io/apimachinery/pkg/labels"
# to "k8s.io/apimachinery/pkg/labels"
vim /root/down/atomic-openshift-git-0.4aab273/pkg/apps/apiserver/registry/deployconfig/etcd/etcd.go
# only to build linux/amd64
vim /root/down/atomic-openshift-git-0.4aab273/hack/build-cross.sh
tar zcf atomic-openshift-git-0.4aab273.tar.gz ./atomic-openshift-git-0.4aab273
/bin/cp -f atomic-openshift-git-0.4aab273.tar.gz ~/rpmbuild/SOURCES/
# change origin.spec, remove goversioninfo, remove windows build
/bin/cp -f origin.spec /root/rpmbuild/SPECS/
cd /root/rpmbuild/SPECS/
rpmbuild -ba origin.spec

export GOPATH=/root/rpmbuild/BUILD/atomic-openshift-3.11.146/_output/local/
```
编译成功以后，会有如下的一堆rpm出现。
![](imgs/2019-10-12-19-58-00.png)

```bash
# https://github.com/openshift/origin/blob/master/HACKING.md
OS_IMAGE_PREFIX=openshift3/ose build-local-images.py
```

## for arm

on aws, create a ec2 on arm, 8c 16g.

![](imgs/2019-10-13-11-51-33.png)
```bash
subscription-manager attach --pool=8a85f99a684d00130168825ebedc1bd1

subscription-manager repos --list

subscription-manager repos \
    --enable="rhel-7-for-arm-64-rpms" \
    --enable="rhel-7-for-arm-64-extras-rpms" \
    --enable="rhel-7-for-arm-64-optional-rpms"

yum -y install rpmdevtools
rpmdev-setuptree
yum -y install wget yum-utils createrepo docker git 
yum -y install git docker
systemctl start docker
yum -y install vim goversioninfo bsdtar golang krb5-devel
yumdownloader --source atomic-openshift
```