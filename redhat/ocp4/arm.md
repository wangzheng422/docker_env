# 参考资料

https://adam.younglogic.com/2017/08/openshift-origin-from-source/

https://github.com/Project31/ansible-kubernetes-openshift-pi3

```bash
yum groupinstall "Development Tools"

yum install git docker

yum install golang make gcc zip mercurial krb5-devel bsdtar bc rsync bind-utils file jq tito createrepo openssl gpgme gpgme-devel libassuan libassuan-devel

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

docker volume prune -f
docker image rm -f $(docker image ls -qa)

# atomic-openshift
yum install yum-utils
yumdownloader --source atomic-openshift

subscription-manager repos --enable=rhel-7-server-ose-3.11-source-rpms
subscription-manager repos --disable=rhel-7-server-ose-3.11-source-rpms
reposync -n -d -l -m --source -r rhel-7-server-ose-3.11-source-rpms
```