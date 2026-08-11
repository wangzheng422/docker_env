#!/usr/bin/env bash

export tag="v3.11.248"
export private_repo="registry.redhat.ren:5443"
export major_tag="v3.11"
# https://access.redhat.com/articles/2834301
# docker search rhgs3 | grep redhat.io | awk '{print $2}'

## 后续导入的时候，要用2个版本号
ose3_images=$(cat << EOF
registry.redhat.io/openshift3/apb-base:$tag
registry.redhat.io/openshift3/apb-tools:$tag
registry.redhat.io/openshift3/automation-broker-apb:$tag
registry.redhat.io/openshift3/csi-attacher:$tag
registry.redhat.io/openshift3/csi-driver-registrar:$tag
registry.redhat.io/openshift3/csi-livenessprobe:$tag
registry.redhat.io/openshift3/csi-provisioner:$tag
registry.redhat.io/openshift3/grafana:$tag
registry.redhat.io/openshift3/local-storage-provisioner:$tag
registry.redhat.io/openshift3/manila-provisioner:$tag
registry.redhat.io/openshift3/mariadb-apb:$tag
registry.redhat.io/openshift3/mediawiki:$tag
registry.redhat.io/openshift3/mediawiki-apb:$tag
registry.redhat.io/openshift3/mysql-apb:$tag
registry.redhat.io/openshift3/ose-ansible-service-broker:$tag
registry.redhat.io/openshift3/ose-cli:$tag
registry.redhat.io/openshift3/ose-cluster-autoscaler:$tag
registry.redhat.io/openshift3/ose-cluster-capacity:$tag
registry.redhat.io/openshift3/ose-cluster-monitoring-operator:$tag
registry.redhat.io/openshift3/ose-console:$tag
registry.redhat.io/openshift3/ose-configmap-reloader:$tag
registry.redhat.io/openshift3/ose-control-plane:$tag
registry.redhat.io/openshift3/ose-deployer:$tag
registry.redhat.io/openshift3/ose-descheduler:$tag
registry.redhat.io/openshift3/ose-docker-builder:$tag
registry.redhat.io/openshift3/ose-docker-registry:$tag
registry.redhat.io/openshift3/ose-efs-provisioner:$tag
registry.redhat.io/openshift3/ose-egress-dns-proxy:$tag
registry.redhat.io/openshift3/ose-egress-http-proxy:$tag
registry.redhat.io/openshift3/ose-egress-router:$tag
registry.redhat.io/openshift3/ose-haproxy-router:$tag
registry.redhat.io/openshift3/ose-hyperkube:$tag
registry.redhat.io/openshift3/ose-hypershift:$tag
registry.redhat.io/openshift3/ose-keepalived-ipfailover:$tag
registry.redhat.io/openshift3/ose-kube-rbac-proxy:$tag
registry.redhat.io/openshift3/ose-kube-state-metrics:$tag
registry.redhat.io/openshift3/ose-metrics-server:$tag
registry.redhat.io/openshift3/ose-node:$tag
registry.redhat.io/openshift3/ose-node-problem-detector:$tag
registry.redhat.io/openshift3/ose-operator-lifecycle-manager:$tag
registry.redhat.io/openshift3/ose-ovn-kubernetes:$tag
registry.redhat.io/openshift3/ose-pod:$tag
registry.redhat.io/openshift3/ose-prometheus-config-reloader:$tag
registry.redhat.io/openshift3/ose-prometheus-operator:$tag
registry.redhat.io/openshift3/ose-recycler:$tag
registry.redhat.io/openshift3/ose-service-catalog:$tag
registry.redhat.io/openshift3/ose-template-service-broker:$tag
registry.redhat.io/openshift3/ose-tests:$tag
registry.redhat.io/openshift3/ose-web-console:$tag
registry.redhat.io/openshift3/postgresql-apb:$tag
registry.redhat.io/openshift3/registry-console:$tag
registry.redhat.io/openshift3/snapshot-controller:$tag
registry.redhat.io/openshift3/snapshot-provisioner:$tag

registry.redhat.io/openshift3/ose-efs-provisioner:$tag
registry.redhat.io/openshift3/metrics-cassandra:$tag
registry.redhat.io/openshift3/metrics-hawkular-metrics:$tag
registry.redhat.io/openshift3/metrics-hawkular-openshift-agent:$tag
registry.redhat.io/openshift3/metrics-heapster:$tag
registry.redhat.io/openshift3/metrics-schema-installer:$tag
registry.redhat.io/openshift3/oauth-proxy:$tag
registry.redhat.io/openshift3/ose-logging-curator5:$tag
registry.redhat.io/openshift3/ose-logging-elasticsearch5:$tag
registry.redhat.io/openshift3/ose-logging-eventrouter:$tag
registry.redhat.io/openshift3/ose-logging-fluentd:$tag
registry.redhat.io/openshift3/ose-logging-kibana5:$tag
registry.redhat.io/openshift3/prometheus:$tag
registry.redhat.io/openshift3/prometheus-alertmanager:$tag
registry.redhat.io/openshift3/prometheus-node-exporter:$tag
registry.redhat.io/cloudforms46/cfme-openshift-postgresql
registry.redhat.io/cloudforms46/cfme-openshift-memcached
registry.redhat.io/cloudforms46/cfme-openshift-app-ui
registry.redhat.io/cloudforms46/cfme-openshift-app
registry.redhat.io/cloudforms46/cfme-openshift-embedded-ansible
registry.redhat.io/cloudforms46/cfme-openshift-httpd
registry.redhat.io/cloudforms46/cfme-httpd-configmap-generator
registry.redhat.io/rhgs3/rhgs-server-rhel7
registry.redhat.io/rhgs3/rhgs-volmanager-rhel7
registry.redhat.io/rhgs3/rhgs-gluster-block-prov-rhel7
registry.redhat.io/rhgs3/rhgs-s3-server-rhel7
registry.redhat.io/jboss-amq-6/amq63-openshift:$tag
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift:$tag
registry.redhat.io/jboss-datagrid-7/datagrid71-client-openshift:$tag
registry.redhat.io/jboss-datavirt-6/datavirt63-openshift:$tag
registry.redhat.io/jboss-datavirt-6/datavirt63-driver-openshift:$tag
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:$tag
registry.redhat.io/jboss-processserver-6/processserver64-openshift:$tag
registry.redhat.io/jboss-eap-6/eap64-openshift:$tag
registry.redhat.io/jboss-eap-7/eap71-openshift:$tag
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift:$tag
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift:$tag
registry.redhat.io/openshift3/jenkins-2-rhel7:$tag
registry.redhat.io/openshift3/jenkins-agent-maven-35-rhel7:$tag
registry.redhat.io/openshift3/jenkins-agent-nodejs-8-rhel7:$tag
registry.redhat.io/openshift3/jenkins-slave-base-rhel7:$tag
registry.redhat.io/openshift3/jenkins-slave-maven-rhel7:$tag
registry.redhat.io/openshift3/jenkins-slave-nodejs-rhel7:$tag
registry.redhat.io/rhscl/mongodb-32-rhel7:$tag
registry.redhat.io/rhscl/mysql-57-rhel7:$tag
registry.redhat.io/rhscl/perl-524-rhel7:$tag
registry.redhat.io/rhscl/php-56-rhel7:$tag
registry.redhat.io/rhscl/postgresql-95-rhel7:$tag
registry.redhat.io/rhscl/python-35-rhel7:$tag
registry.redhat.io/redhat-sso-7/sso70-openshift:$tag
registry.redhat.io/rhscl/ruby-24-rhel7:$tag
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:$tag
registry.redhat.io/redhat-sso-7/sso71-openshift:$tag
registry.redhat.io/rhscl/nodejs-6-rhel7:$tag
registry.redhat.io/rhscl/mariadb-101-rhel7:$tag

registry.redhat.io/openshift3/ose-ansible:v3.11
EOF
)

## 后续导入的时候，不要更改版本号
ose3_optional_imags=$(cat << EOF

registry.redhat.io/rhel7/etcd:3.2.26

EOF
)

## 后续导入的时候，可以更改版本号
ose3_builder_images=$(cat << EOF
registry.redhat.io/cloudforms46/cfme-openshift-postgresql
registry.redhat.io/cloudforms46/cfme-openshift-memcached
registry.redhat.io/cloudforms46/cfme-openshift-app-ui
registry.redhat.io/cloudforms46/cfme-openshift-app
registry.redhat.io/cloudforms46/cfme-openshift-embedded-ansible
registry.redhat.io/cloudforms46/cfme-openshift-httpd
registry.redhat.io/cloudforms46/cfme-httpd-configmap-generator

registry.redhat.io/rhgs3/rhgs-server-rhel7
registry.redhat.io/rhgs3/rhgs-volmanager-rhel7
registry.redhat.io/rhgs3/rhgs-gluster-block-prov-rhel7
registry.redhat.io/rhgs3/rhgs-s3-server-rhel7

registry.redhat.io/jboss-amq-6/amq63-openshift
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift
registry.redhat.io/jboss-datagrid-7/datagrid71-client-openshift
registry.redhat.io/jboss-datavirt-6/datavirt63-openshift
registry.redhat.io/jboss-datavirt-6/datavirt63-driver-openshift
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift
registry.redhat.io/jboss-processserver-6/processserver64-openshift
registry.redhat.io/jboss-eap-6/eap64-openshift
registry.redhat.io/jboss-eap-7/eap71-openshift
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift

registry.redhat.io/rhscl-beta/devtoolset-8-perftools-rhel7
registry.redhat.io/rhscl-beta/devtoolset-8-toolchain-rhel7
registry.redhat.io/rhscl-beta/httpd-24-rhel7
registry.redhat.io/rhscl-beta/mariadb-103-rhel7
registry.redhat.io/rhscl-beta/redis-5-rhel7
registry.redhat.io/rhscl-beta/ruby-26-rhel7
registry.redhat.io/rhscl-beta/varnish-6-rhel7
registry.redhat.io/rhscl/devtoolset-4-perftools-rhel7
registry.redhat.io/rhscl/devtoolset-4-toolchain-rhel7
registry.redhat.io/rhscl/devtoolset-6-perftools-rhel7
registry.redhat.io/rhscl/devtoolset-6-toolchain-rhel7
registry.redhat.io/rhscl/devtoolset-7-perftools-rhel7
registry.redhat.io/rhscl/devtoolset-7-toolchain-rhel7
registry.redhat.io/rhscl/devtoolset-8-perftools-rhel7
registry.redhat.io/rhscl/devtoolset-8-toolchain-rhel7
registry.redhat.io/rhscl/go-toolset-7-rhel7
registry.redhat.io/rhscl/httpd-24-rhel7
registry.redhat.io/rhscl/llvm-toolset-7-rhel7
registry.redhat.io/rhscl/mariadb-100-rhel7
registry.redhat.io/rhscl/mariadb-101-rhel7
registry.redhat.io/rhscl/mariadb-102-rhel7
registry.redhat.io/rhscl/mongodb-26-rhel7
registry.redhat.io/rhscl/mongodb-32-rhel7
registry.redhat.io/rhscl/mongodb-34-rhel7
registry.redhat.io/rhscl/mongodb-36-rhel7
registry.redhat.io/rhscl/mysql-56-rhel7
registry.redhat.io/rhscl/mysql-57-rhel7
registry.redhat.io/rhscl/mysql-80-rhel7
registry.redhat.io/rhscl/nginx-110-rhel7
registry.redhat.io/rhscl/nginx-112-rhel7
registry.redhat.io/rhscl/nginx-114-rhel7
registry.redhat.io/rhscl/nginx-16-rhel7
registry.redhat.io/rhscl/nginx-18-rhel7
registry.redhat.io/rhscl/nodejs-10-rhel7
registry.redhat.io/rhscl/nodejs-4-rhel7
registry.redhat.io/rhscl/nodejs-6-rhel7
registry.redhat.io/rhscl/nodejs-8-rhel7
registry.redhat.io/rhscl/passenger-40-rhel7
registry.redhat.io/rhscl/perl-520-rhel7
registry.redhat.io/rhscl/perl-524-rhel7
registry.redhat.io/rhscl/perl-526-rhel7
registry.redhat.io/rhscl/php-56-rhel7
registry.redhat.io/rhscl/php-70-rhel7
registry.redhat.io/rhscl/php-71-rhel7
registry.redhat.io/rhscl/php-72-rhel7
registry.redhat.io/rhscl/postgresql-10-rhel7
registry.redhat.io/rhscl/postgresql-94-rhel7
registry.redhat.io/rhscl/postgresql-95-rhel7
registry.redhat.io/rhscl/postgresql-96-rhel7
registry.redhat.io/rhscl/python-27-rhel7
registry.redhat.io/rhscl/python-34-rhel7
registry.redhat.io/rhscl/python-35-rhel7
registry.redhat.io/rhscl/python-36-rhel7
registry.redhat.io/rhscl/redis-32-rhel7
registry.redhat.io/rhscl/ror-41-rhel7
registry.redhat.io/rhscl/ror-42-rhel7
registry.redhat.io/rhscl/ror-50-rhel7
registry.redhat.io/rhscl/ruby-22-rhel7
registry.redhat.io/rhscl/ruby-23-rhel7
registry.redhat.io/rhscl/ruby-24-rhel7
registry.redhat.io/rhscl/ruby-25-rhel7
registry.redhat.io/rhscl/rust-toolset-7-rhel7
registry.redhat.io/rhscl/s2i-base-rhel7
registry.redhat.io/rhscl/s2i-core-rhel7
registry.redhat.io/rhscl/thermostat-1-agent-rhel7
registry.redhat.io/rhscl/thermostat-16-agent-rhel7
registry.redhat.io/rhscl/thermostat-16-storage-rhel7
registry.redhat.io/rhscl/varnish-4-rhel7
registry.redhat.io/rhscl/varnish-5-rhel7
registry.redhat.io/rhscl/varnish-6-rhel7

registry.redhat.io/cloudforms46/cfme-httpd-configmap-generator
registry.redhat.io/cloudforms46/cfme-openshift-app
registry.redhat.io/cloudforms46/cfme-openshift-app-ui
registry.redhat.io/cloudforms46/cfme-openshift-embedded-ansible
registry.redhat.io/cloudforms46/cfme-openshift-httpd
registry.redhat.io/cloudforms46/cfme-openshift-memcached
registry.redhat.io/cloudforms46/cfme-openshift-postgresql

registry.redhat.io/jboss-amq-6/amq62-openshift
registry.redhat.io/jboss-amq-6/amq63-openshift

registry.redhat.io/jboss-datagrid-6/datagrid65-client-openshift
registry.redhat.io/jboss-datagrid-6/datagrid65-openshift
registry.redhat.io/jboss-datagrid-7/datagrid71-client-openshift
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift
registry.redhat.io/jboss-datagrid-7/datagrid72-openshift
registry.redhat.io/jboss-datagrid-7/datagrid73-openshift

registry.redhat.io/jboss-datavirt-6/datavirt63-driver-openshift
registry.redhat.io/jboss-datavirt-6/datavirt63-openshift
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift
registry.redhat.io/jboss-decisionserver-6/decisionserver62-openshift
registry.redhat.io/jboss-decisionserver-6/decisionserver63-openshift
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift
registry.redhat.io/jboss-eap-6/eap64-openshift

registry.redhat.io/jboss-eap-7/eap70-openshift
registry.redhat.io/jboss-eap-7/eap71-openshift
registry.redhat.io/jboss-eap-7/eap72-openshift
registry.redhat.io/jboss-fuse-6/fis-java-openshift
registry.redhat.io/jboss-fuse-6/fis-karaf-openshift
registry.redhat.io/jboss-processserver-6/processserver63-openshift
registry.redhat.io/jboss-processserver-6/processserver64-openshift
registry.redhat.io/jboss-webserver-3/webserver30-tomcat7-openshift
registry.redhat.io/jboss-webserver-3/webserver30-tomcat8-openshift
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift
registry.redhat.io/jboss-webserver-5/webserver50-tomcat9-openshift

EOF
)

## Container-native virtualization 
cnv_optional_imags=$(cat << EOF

registry.redhat.io/cnv-tech-preview/cnv-libvirt
registry.redhat.io/cnv-tech-preview/ember-csi
registry.redhat.io/cnv-tech-preview/ember-csi-operator
registry.redhat.io/cnv-tech-preview/kubevirt-cpu-model-nfd-plugin
registry.redhat.io/cnv-tech-preview/kubevirt-cpu-node-labeller
registry.redhat.io/cnv-tech-preview/kubevirt-metrics-collector
registry.redhat.io/cnv-tech-preview/kubevirt-operator
registry.redhat.io/cnv-tech-preview/kubevirt-web-ui
registry.redhat.io/cnv-tech-preview/kubevirt-web-ui-operator
registry.redhat.io/cnv-tech-preview/multus-cni
registry.redhat.io/cnv-tech-preview/ovs-cni-plugin
registry.redhat.io/cnv-tech-preview/sriov-cni
registry.redhat.io/cnv-tech-preview/sriov-network-device-plugin
registry.redhat.io/cnv-tech-preview/virt-api
registry.redhat.io/cnv-tech-preview/virt-cdi-apiserver
registry.redhat.io/cnv-tech-preview/virt-cdi-cloner
registry.redhat.io/cnv-tech-preview/virt-cdi-controller
registry.redhat.io/cnv-tech-preview/virt-cdi-importer
registry.redhat.io/cnv-tech-preview/virt-cdi-operator
registry.redhat.io/cnv-tech-preview/virt-cdi-uploadproxy
registry.redhat.io/cnv-tech-preview/virt-cdi-uploadserver
registry.redhat.io/cnv-tech-preview/virt-controller
registry.redhat.io/cnv-tech-preview/virt-handler
registry.redhat.io/cnv-tech-preview/virt-launcher
registry.redhat.io/cnv-tech-preview/virt-operator
registry.redhat.io/cnv-tech-preview/virtio-win
registry.redhat.io/cnv-tech-preview/virtio-win-container
registry.redhat.io/cnv-tech-preview/vmctl

EOF
)

## istio, Red Hat OpenShift Service Mesh 
# docker search istio | grep redhat.io | awk '{print $2}'
# docker search distributed-tracing | grep redhat.io | awk '{print $2}'
istio_optional_imags=$(cat << EOF

registry.redhat.io/openshift-istio-tech-preview/3scale-istio-adapter
registry.redhat.io/openshift-istio-tech-preview/3scale-istio-adapter-tech-preview
registry.redhat.io/openshift-istio-tech-preview/citadel
registry.redhat.io/openshift-istio-tech-preview/galley
registry.redhat.io/openshift-istio-tech-preview/istio-ior
registry.redhat.io/openshift-istio-tech-preview/istio-operator
registry.redhat.io/openshift-istio-tech-preview/kiali
registry.redhat.io/openshift-istio-tech-preview/mixer
registry.redhat.io/openshift-istio-tech-preview/openshift-ansible
registry.redhat.io/openshift-istio-tech-preview/pilot
registry.redhat.io/openshift-istio-tech-preview/proxy-init
registry.redhat.io/openshift-istio-tech-preview/proxyv2
registry.redhat.io/openshift-istio-tech-preview/sidecar-injector
registry.redhat.io/openshift-istio/citadel
registry.redhat.io/openshift-istio/galley
registry.redhat.io/openshift-istio/istio-operator
registry.redhat.io/openshift-istio/kiali
registry.redhat.io/openshift-istio/mixer
registry.redhat.io/openshift-istio/openshift-ansible
registry.redhat.io/openshift-istio/pilot
registry.redhat.io/openshift-istio/proxy-init
registry.redhat.io/openshift-istio/proxyv2
registry.redhat.io/openshift-istio/sidecar-injector

registry.redhat.io/distributed-tracing-tech-preview/jaeger-agent
registry.redhat.io/distributed-tracing-tech-preview/jaeger-all-in-one
registry.redhat.io/distributed-tracing-tech-preview/jaeger-collector
registry.redhat.io/distributed-tracing-tech-preview/jaeger-elasticsearch
registry.redhat.io/distributed-tracing-tech-preview/jaeger-ingester
registry.redhat.io/distributed-tracing-tech-preview/jaeger-operator
registry.redhat.io/distributed-tracing-tech-preview/jaeger-query
registry.redhat.io/distributed-tracing/jaeger-agent
registry.redhat.io/distributed-tracing/jaeger-collector
registry.redhat.io/distributed-tracing/jaeger-elasticsearch
registry.redhat.io/distributed-tracing/jaeger-query


EOF
)


docker_builder_images=$(cat << EOF
gitlab/gitlab-ce
nfvpe/sriov-device-plugin:latest
centos/tools 
nfvpe/multus:latest
kubevirt/virt-api:v0.14.0
kubevirt/virt-launcher:v0.14.0
kubevirt/virt-controller:v0.14.0
kubevirt/virt-handler:v0.14.0
kubevirt/cirros-registry-disk-demo
kubevirt/container-disk-v1alpha
kubevirt/virt-operator:v0.14.0
nvidia/k8s-device-plugin:1.11
mirrorgooglecontainers/cuda-vector-add:v0.1
openshift/oauth-proxy:v1.1.0
chartmuseum/chartmuseum
nicolaka/netshoot
dougbtv/dhcp
EOF
)

quay_builder_images=$(cat << EOF
quay.io/coreos/flannel:v0.10.0-amd64
quay.io/coreos/flannel:v0.10.0-arm64
quay.io/coreos/flannel:v0.10.0-ppc64le
quay.io/coreos/flannel:v0.10.0-s390x
quay.io/kubevirt/kubevirt-web-ui-operator:v1.4.0
quay.io/kubevirt/kubevirt-web-ui:v1.4.0-14
# quay.io/openshift/origin-metering-helm-operator
# quay.io/openshift/origin-metering-reporting-operator
quay.io/openshift/origin-metering-presto
quay.io/openshift/origin-metering-hive
quay.io/openshift/origin-metering-hadoop
# quay.io/openshift/origin-metering-helm-operator:4.1
quay.io/kubernetes-multicluster/federation-v2:v0.0.10
quay.io/kubernetes-multicluster/kubefed:v0.1.0-rc2
EOF
)

gcr_builder_images=$(cat << EOF
gcr.io/kubernetes-helm/tiller:v2.14.1

EOF
)