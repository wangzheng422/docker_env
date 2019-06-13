# federation v2

https://github.com/kubernetes-sigs/kubefed/releases

https://www.cnblogs.com/rongfengliang/p/8862255.html

## install

先装chartmuseum

```bash
curl -LO https://s3.amazonaws.com/chartmuseum/release/latest/bin/linux/amd64/chartmuseum

chmod +x chartmuseum
mkdir -p ./chartstorage

./chartmuseum --debug --port=8080 \
  --storage="local" \
  --storage-local-rootdir="./chartstorage"
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
firewall-cmd --list-all

wget https://get.helm.sh/helm-v2.14.1-linux-amd64.tar.gz

# echo HELM_HOME=$(pwd)
./helm init --client-only
./helm create gateway
./helm plugin install https://github.com/chartmuseum/helm-push
./helm repo add chartmuseum http://localhost:8080
./helm push gateway/ chartmuseum
./helm search chartmuseum/

wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.1.0-rc2/kubefed-0.1.0-rc2.tgz

docker pull quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc2
docker tag quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc2 aws-registry.redhat.ren/kubernetes-multicluster/kubefed:v0.1.0-rc2 
docker push aws-registry.redhat.ren/kubernetes-multicluster/kubefed:v0.1.0-rc2 

docker pull gcr.io/kubernetes-helm/tiller:v2.14.1
docker tag gcr.io/kubernetes-helm/tiller:v2.14.0 aws-registry.redhat.ren/kubernetes-helm/tiller:v2.14.1
docker push aws-registry.redhat.ren/kubernetes-helm/tiller:v2.14.1


# change ./kubefed/values

cd kubefed/
../linux-amd64/helm package .
./linux-amd64/helm push kubefed/ chartmuseum

scp helm-v2.14.1-linux-amd64.tar.gz ec2-user@aws-m1.redhat.ren:~/
scp kubefed-0.1.0-rc2.tgz ec2-user@aws-m1.redhat.ren:~/
scp kubefedctl-0.1.0-rc2-linux-amd64.tgz ec2-user@aws-m1.redhat.ren:~/

# on aws-m1
tar zvxf helm-v2.14.1-linux-amd64.tar.gz
./linux-amd64/helm init --client-only --stable-repo-url http://aws-registry.redhat.ren:8080/
./linux-amd64/helm repo add chartmuseum http://aws-registry.redhat.ren:8080/
./linux-amd64/helm search chartmuseum/

sudo -i
cd /home/ec2-user/
oc new-project federation-system
oc new-project tiller
oc project tiller

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: federation-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: federation-system
EOF

./linux-amd64/helm init --service-account tiller --client-only --stable-repo-url http://aws-registry.redhat.ren:8080/  #--tiller-tls-verify

export TILLER_NAMESPACE=tiller
oc process -f ./tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.14.1 | oc create -f -

oc --namespace=tiller set image deployments/tiller-deploy tiller=aws-registry.redhat.ren/kubernetes-helm/tiller:v2.14.1 
oc --namespace=kube-system set image deployments/tiller-deploy tiller=aws-registry.redhat.ren/kubernetes-helm/tiller:v2.14.1 

## delete tiller
oc project tiller
oc process -f ./tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.14.1 | oc delete -f -

./linux-amd64/helm version

./linux-amd64/helm init --client-only --stable-repo-url http://aws-registry.redhat.ren:8080/
./linux-amd64/helm repo add chartmuseum http://aws-registry.redhat.ren:8080/
./linux-amd64/helm search chartmuseum/
./linux-amd64/helm repo list

# ./linux-amd64/helm install chartmuseum/kubefed --name kubefed --namespace kube-federation-system --values values.yaml

# oc new-project federation-system
oc project federation-system
oc policy add-role-to-user edit "system:serviceaccount:${TILLER_NAMESPACE}:tiller"
# oc policy add-role-to-user edit "system:serviceaccount:kube-federation-system:tiller"

kubectl create clusterrolebinding cluster-admin-binding-helm   --clusterrole=cluster-admin   --user=system:serviceaccount:${TILLER_NAMESPACE}:tiller

./linux-amd64/helm install ./kubefed-0.1.0-rc2.tgz --name kubefed --namespace federation-system --values values.yaml

# delete fed
kubectl -n federation-system delete FederatedTypeConfig --all
kubectl delete crd $(kubectl get crd | grep -E 'kubefed.k8s.io' | awk '{print $1}')
./linux-amd64/helm delete --purge kubefed

wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.1.0-rc2/kubefedctl-0.1.0-rc2-linux-amd64.tgz

scp kubefedctl-0.1.0-rc2-linux-amd64.tgz ec2-user@aws-m1.redhat.ren:~/

kubefedctl join cluster1 --cluster-context cluster1 \
    --host-cluster-context cluster1 --v=2

oc config
oc config get-clusters
oc config get-contexts
oc login https://aws-m2-paas.redhat.ren:8443

##############
NAME
aws-m1-redhat-ren:8443
aws-m2-paas-redhat-ren:8443
aws-paas-redhat-ren:8443
##############

./kubefedctl join m1 --kubefed-namespace federation-system --cluster-context tiller/aws-m1-redhat-ren:8443/system:admin   --host-cluster-context tiller/aws-m1-redhat-ren:8443/system:admin --host-cluster-name aws-m1-redhat-ren cluster1 --v=2

./kubefedctl join m2 --kubefed-namespace federation-system --cluster-context default/aws-m2-paas-redhat-ren:8443/admin   --host-cluster-context tiller/aws-m1-redhat-ren:8443/system:admin --host-cluster-name aws-m1-redhat-ren cluster1 --v=2

oc -n federation-system get kubefedclusters

oc get kubefedcluster m2 -n federation-system -o yaml

./kubefedctl unjoin m2 --kubefed-namespace federation-system --cluster-context default/aws-m2-paas-redhat-ren:8443/admin   --host-cluster-context tiller/aws-m1-redhat-ren:8443/system:admin --host-cluster-name aws-m1-redhat-ren cluster1 --v=2

oc config rename-context default/aws-m2-paas-redhat-ren:8443/admin m2

oc config rename-context default/aws-m1-redhat-ren:8443/system:admin m1

./kubefedctl join m2 --kubefed-namespace federation-system  --host-cluster-context=m1 --cluster-context=m2 

./kubefedctl unjoin m2 --kubefed-namespace federation-system  --host-cluster-context=m1 --cluster-context=m2

./kubefedctl unjoin m1 --kubefed-namespace federation-system  --host-cluster-context=m1 --cluster-context=m1

./kubefedctl join m2 --kubefed-namespace federation-system  —host-cluster-context=m1 —cluster-context=m2 -v 8

oc get kubefedconfig -o yaml

```

















## failed

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

docker tag chartmuseum/chartmuseum aws-registry.redhat.ren/chartmuseum/chartmuseum
docker tag quay.io/kubernetes-multicluster/federation-v2:v0.0.10 aws-registry.redhat.ren/kubernetes-multicluster/federation-v2
docker tag quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc1 aws-registry.redhat.ren/kubernetes-multicluster/kubefed
docker tag gcr.io/kubernetes-helm/tiller:v2.14.0 aws-registry.redhat.ren/kubernetes-helm/tiller

docker push aws-registry.redhat.ren/chartmuseum/chartmuseum
docker push aws-registry.redhat.ren/kubernetes-multicluster/federation-v2
docker push aws-registry.redhat.ren/kubernetes-helm/tiller

chown -R 1000:1000 charts


```
