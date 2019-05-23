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
docker pull gcr.io/kubernetes-helm/tiller:v2.14.0

docker save chartmuseum/chartmuseum quay.io/kubernetes-multicluster/federation-v2:v0.0.10 gcr.io/kubernetes-helm/tiller:v2.14.0 | gzip > federation.tgz
```