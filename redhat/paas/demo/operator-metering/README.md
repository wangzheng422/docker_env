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


