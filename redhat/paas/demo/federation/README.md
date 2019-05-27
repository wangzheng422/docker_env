# federation v2

```bash
oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.14.0 | oc create -f -


docker run --rm -it \
  -p 8080:8080 \
  -v $(pwd)/charts:/charts \
  -e DEBUG=true \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  chartmuseum/chartmuseum


docker pull chartmuseum/chartmuseum
docker pull quay.io/kubernetes-multicluster/federation-v2:v0.0.10
docker pull quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc1
docker pull gcr.io/kubernetes-helm/tiller:v2.14.0

docker save chartmuseum/chartmuseum quay.io/kubernetes-multicluster/federation-v2:v0.0.10 quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc1 gcr.io/kubernetes-helm/tiller:v2.14.0 | gzip > federation.tgz
```

先下载以下的内容，https://github.com/kubernetes-sigs/kubefed/releases，应该下载2个，一个是kubefedctl , 另外一个是helm chart (federation-v2-***).

根据以下的说明，准备安装helm
https://blog.openshift.com/getting-started-helm-openshift/

按照上面的命令，运行一个chart。

修改index.yaml，把这个文件copy到chart目录上去。同时把helm chart也复制上去。

```bash

docker run --rm -it \
  -p 5080:5080 \
  -v /root/down/charts:/charts \
  -e DEBUG=true \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  chartmuseum/chartmuseum

docker run --rm -it \
  -p 5080:5080 \
  -v $(pwd)/charts:/charts \
  -e DEBUG=true \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  chartmuseum/chartmuseum

docker load -i federation.tgz

docker tag chartmuseum/chartmuseum it-registry.redhat.ren:5021/chartmuseum/chartmuseum
docker tag quay.io/kubernetes-multicluster/federation-v2:v0.0.10 it-registry.redhat.ren:5021/kubernetes-multicluster/federation-v2
docker tag quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc1 it-registry.redhat.ren:5021/kubernetes-multicluster/kubefed
docker tag gcr.io/kubernetes-helm/tiller:v2.14.0 it-registry.redhat.ren:5021/kubernetes-helm/tiller

docker push it-registry.redhat.ren:5021/chartmuseum/chartmuseum
docker push it-registry.redhat.ren:5021/kubernetes-multicluster/federation-v2
docker push it-registry.redhat.ren:5021/kubernetes-helm/tiller

chown -R 1000:1000 charts


```
