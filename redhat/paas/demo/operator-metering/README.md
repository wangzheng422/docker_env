# operator metering

## 打包

```bash

# https://github.com/operator-framework/operator-metering/blob/master/Documentation/dev/ocp-images.md

hack/ocp-util/ocp-image-pull-and-rename.sh

make docker-build-all OCP_BUILD=true USE_IMAGEBUILDER=true RELEASE_TAG=v4.0

docker tag quay.io/openshift/origin-metering-helm-operator:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator:4.1

docker tag quay.io/openshift/origin-metering-helm-operator:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator

docker tag quay.io/openshift/origin-metering-reporting-operator:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-reporting-operator:4.1 

docker tag openshift/oauth-proxy:v1.1.0 it-registry.redhat.ren:5021/openshift/oauth-proxy:v1.1.0

docker pull quay.io/openshift/origin-metering-presto:4.1 
docker tag quay.io/openshift/origin-metering-presto:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-presto:4.1

docker pull quay.io/openshift/origin-metering-hive:4.1 
docker tag quay.io/openshift/origin-metering-hive:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-hive:4.1

docker pull quay.io/openshift/origin-metering-hadoop:4.1 
docker tag quay.io/openshift/origin-metering-hadoop:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-hadoop:4.1


docker save it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator it-registry.redhat.ren:5021/openshift/origin-metering-reporting-operator:4.1 it-registry.redhat.ren:5021/openshift/oauth-proxy:v1.1.0 it-registry.redhat.ren:5021/openshift/origin-metering-presto:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-hive:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-hadoop:4.1 | gzip -c > metering.tgz

docker push it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator:4.1
docker push it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator
docker push it-registry.redhat.ren:5021/openshift/origin-metering-reporting-operator:4.1
docker push it-registry.redhat.ren:5021/openshift/oauth-proxy:v1.1.0
docker push it-registry.redhat.ren:5021/openshift/origin-metering-presto:4.1
docker push it-registry.redhat.ren:5021/openshift/origin-metering-hive:4.1
docker push it-registry.redhat.ren:5021/openshift/origin-metering-hadoop:4.1 

docker tag quay.io/openshift/origin-metering-helm-operator:4.1 it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator:4.1

```

## 适配离线部署

https://github.com/wangzheng422/operator-metering/tree/eastnet-20190517

这个项目更改了原来项目中的image url，如果是新的项目，那么，修改和运行update.sh，重新编译，就可以在新环境里面使用了。

```bash

docker save it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator:4.1 | gzip -c > m-op.tgz

docker push it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator:4.1

export METERING_NAMESPACE=metering-wzh
export METERING_CR_FILE=metering-custom.yaml

export METERING_OPERATOR_IMAGE_REPO=it-registry.redhat.ren:5021/openshift/origin-metering-helm-operator
export METERING_OPERATOR_IMAGE_TAG=4.1
./hack/openshift-install.sh

```

## 使用

```bash

kubectl get reportqueries -n metering-wzh

mkdir -p /root/yml/
cat << EOF > /root/yml/metering-report.yml
apiVersion: metering.openshift.io/v1alpha1
kind: Report
metadata:
  name: namespace-cpu-request
spec:
  reportingStart: '2019-05-21T07:00:00Z'
  reportingEnd: '2019-05-21T07:30:00Z'
  query: "namespace-cpu-request"
  runImmediately: true
EOF

kubectl -n metering-wzh create -f /root/yml/metering-report.yml

kubectl -n metering-wzh get reports

kubectl -n metering-wzh get report namespace-cpu-request -o json

kubectl -n metering-wzh delete -f /root/yml/metering-report.yml

# https://it-paas.redhat.ren:8443/api/v1/reports/get?name=namespace-cpu-request&namespace=metering-wzh&format=csv

kubectl proxy

curl "http://127.0.0.1:8001/api/v1/namespaces/metering-wzh/services/https:reporting-operator:http/proxy/api/v1/reports/get?name=namespace-cpu-request&namespace=metering-wzh&format=csv"

```


