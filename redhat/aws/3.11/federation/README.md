# federation v2 

0.10.0

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
wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.0.10/federation-v2-0.0.10.tgz
wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.0.10/kubefedctl.tgz

docker pull quay.io/kubernetes-multicluster/federation-v2:v0.0.10
docker tag quay.io/kubernetes-multicluster/federation-v2:v0.0.10 aws-registry.redhat.ren/kubernetes-multicluster/federation-v2:v0.0.10 
docker push aws-registry.redhat.ren/kubernetes-multicluster/federation-v2:v0.0.10 

docker pull gcr.io/kubernetes-helm/tiller:v2.14.1
docker tag gcr.io/kubernetes-helm/tiller:v2.14.1 aws-registry.redhat.ren/kubernetes-helm/tiller:v2.14.1
docker push aws-registry.redhat.ren/kubernetes-helm/tiller:v2.14.1

scp helm-v2.14.1-linux-amd64.tar.gz ec2-user@aws-m1.redhat.ren:~/
scp federation-v2-0.0.10.tgz ec2-user@aws-m1.redhat.ren:~/
scp kubefedctl.tgz ec2-user@aws-m1.redhat.ren:~/

# on aws-m1
sudo -i
cd /home/ec2-user/
tar zvxf helm-v2.14.1-linux-amd64.tar.gz
./linux-amd64/helm init --client-only --stable-repo-url http://aws-registry.redhat.ren:8080/
./linux-amd64/helm repo add chartmuseum http://aws-registry.redhat.ren:8080/
./linux-amd64/helm search chartmuseum/

# oc adm new-project kube-federation-system
# oc adm new-project kube-multicluster-public
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

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
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
    namespace: kube-system
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

./linux-amd64/helm install ./federation-v2-0.0.10.tgz --name federation-v2 --namespace federation-system --values values.yaml

# delete fed
kubectl -n kube-federation-system delete FederatedTypeConfig --all
kubectl delete crd $(kubectl get crd | grep -E 'kubefed.k8s.io' | awk '{print $1}')
kubectl delete crd $(kubectl get crd | grep -E 'federation.k8s.io' | awk '{print $1}')
kubectl delete crd $(kubectl get crd | grep -E 'clusterregistry.k8s.io' | awk '{print $1}')
./linux-amd64/helm delete --purge federation-v2


# kubefedctl join cluster1 --cluster-context cluster1 --host-cluster-context cluster1 --v=2

oc config
oc config get-clusters
oc config get-contexts
oc login https://aws-m2-paas.redhat.ren:8443

oc -n federation-system get clusters

oc config rename-context default/aws-m2-paas-redhat-ren:8443/admin m2

oc config rename-context default/aws-m1-redhat-ren:8443/system:admin m1

./kubefedctl join m1 --cluster-context m1 --host-cluster-context m1 --add-to-registry --v=2

./kubefedctl join m2 --host-cluster-context=m1 --cluster-context=m2 --add-to-registry -v 8

./kubefedctl unjoin m2 --cluster-context m2 --host-cluster-context m1 --remove-from-registry --v=2

oc -n federation-system get federatedclusters
oc -n federation-system describe federatedclusters

oc get cluster m2 -n kube-federation-system -o yaml

./kubefedctl unjoin m2 --kubefed-namespace federation-system  --host-cluster-context=m1 --cluster-context=m2

./kubefedctl unjoin m1 --kubefed-namespace federation-system  --host-cluster-context=m1 --cluster-context=m1

./kubefedctl join m2 --kubefed-namespace federation-system  —host-cluster-context=m1 —cluster-context=m2 -v 8

oc get federationconfig -o yaml

```

