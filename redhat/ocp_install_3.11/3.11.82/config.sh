#!/usr/bin/env bash

export tag="v3.11.82"

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
registry.redhat.io/openshift3/image-inspector:$tag
registry.redhat.io/openshift3/local-storage-provisioner:$tag
registry.redhat.io/openshift3/manila-provisioner:$tag
registry.redhat.io/openshift3/mariadb-apb:$tag
registry.redhat.io/openshift3/mediawiki:$tag
registry.redhat.io/openshift3/mediawiki-apb:$tag
registry.redhat.io/openshift3/mysql-apb:$tag
registry.redhat.io/openshift3/ose-ansible:$tag
registry.redhat.io/openshift3/rvice-broker:$tag
registry.redhat.io/openshift3/ose-cli:$tag
registry.redhat.io/openshift3/ose-cluster-autoscaler:$tag
registry.redhat.io/openshift3/ose-cluster-capacity:$tag
registry.redhat.io/openshift3/nitoring-operator:$tag
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
registry.redhat.io/openshift3/ifecycle-manager:$tag
registry.redhat.io/openshift3/ose-ovn-kubernetes:$tag
registry.redhat.io/openshift3/ose-pod:$tag
registry.redhat.io/openshift3/-config-reloader:$tag
registry.redhat.io/openshift3/ose-prometheus-operator:$tag
registry.redhat.io/openshift3/ose-recycler:$tag
registry.redhat.io/openshift3/ose-service-catalog:$tag
registry.redhat.io/openshift3/ervice-broker:$tag
registry.redhat.io/openshift3/ose-tests:$tag
registry.redhat.io/openshift3/ose-web-console:$tag
registry.redhat.io/openshift3/postgresql-apb:$tag
registry.redhat.io/openshift3/registry-console:$tag
registry.redhat.io/openshift3/snapshot-controller:$tag
registry.redhat.io/openshift3/snapshot-provisioner:$tag
registry.redhat.io/openshift3/metrics-cassandra:$tag
registry.redhat.io/openshift3/metrics-hawkular-metrics:$tag
registry.redhat.io/openshift3/ar-openshift-agent:$tag
registry.redhat.io/openshift3/metrics-heapster:$tag
registry.redhat.io/openshift3/metrics-schema-installer:$tag
registry.redhat.io/openshift3/oauth-proxy:$tag
registry.redhat.io/openshift3/ose-logging-curator5:$tag
registry.redhat.io/openshift3/asticsearch5:$tag
registry.redhat.io/openshift3/ose-logging-eventrouter:$tag
registry.redhat.io/openshift3/ose-logging-fluentd:$tag
registry.redhat.io/openshift3/ose-logging-kibana5:$tag
registry.redhat.io/openshift3/prometheus:$tag
registry.redhat.io/openshift3/prometheus-alert-buffer:$tag
registry.redhat.io/openshift3/prometheus-alertmanager:$tag
registry.redhat.io/openshift3/prometheus-node-exporter:$tag

registry.redhat.io/jboss-amq-6/amq63-openshift:$tag
registry.redhat.io/jboss-datagrid-7/nshift:$tag
registry.redhat.io/jboss-datagrid-7/ent-openshift:$tag
registry.redhat.io/jboss-datavirt-6/nshift:$tag
registry.redhat.io/jboss-datavirt-6/ver-openshift:$tag
registry.redhat.io/jboss-decisionserver-6/64-openshift:$tag
registry.redhat.io/jboss-processserver-6/4-openshift:$tag
registry.redhat.io/jboss-eap-6/eap64-openshift:$tag
registry.redhat.io/jboss-eap-7/eap71-openshift:$tag
registry.redhat.io/jboss-webserver-3/mcat7-openshift:$tag
registry.redhat.io/jboss-webserver-3/mcat8-openshift:$tag
registry.redhat.io/openshift3/jenkins-2-rhel7:$tag
registry.redhat.io/openshift3/maven-35-rhel7:$tag
registry.redhat.io/openshift3/nodejs-8-rhel7:$tag
registry.redhat.io/openshift3/jenkins-slave-base-rhel7:$tag
registry.redhat.io/openshift3/jenkins-slave-maven-rhel7:$tag
registry.redhat.io/openshift3/nodejs-rhel7:$tag
registry.redhat.io/rhscl/mongodb-32-rhel7:$tag
registry.redhat.io/rhscl/mysql-57-rhel7:$tag
registry.redhat.io/rhscl/perl-524-rhel7:$tag
registry.redhat.io/rhscl/php-56-rhel7:$tag
registry.redhat.io/rhscl/postgresql-95-rhel7:$tag
registry.redhat.io/rhscl/python-35-rhel7:$tag
registry.redhat.io/redhat-sso-7/sso70-openshift:$tag
registry.redhat.io/rhscl/ruby-24-rhel7:$tag
registry.redhat.io/redhat-openjdk-18/shift:$tag
registry.redhat.io/redhat-sso-7/sso71-openshift:$tag
registry.redhat.io/rhscl/nodejs-6-rhel7:$tag
registry.redhat.io/rhscl/mariadb-101-rhel7:$tag
EOF
)

## 后续导入的时候，不要更改版本号
ose3_optional_imags=$(cat << EOF

registry.redhat.io/rhel7/etcd:3.2.22

EOF
)

## 后续导入的时候，可以更改版本号
ose3_builder_images=$(cat << EOF
registry.redhat.io/cloudforms46/cfme-openshift-postgresql
registry.redhat.io/cloudforms46/cfme-openshift-memcached
registry.redhat.io/cloudforms46/cfme-openshift-app-ui
registry.redhat.io/cloudforms46/cfme-openshift-app
registry.redhat.io/cloudforms46/-embedded-ansible
registry.redhat.io/cloudforms46/cfme-openshift-httpd
registry.redhat.io/cloudforms46/figmap-generator
registry.redhat.io/rhgs3/rhgs-server-rhel7
registry.redhat.io/rhgs3/rhgs-volmanager-rhel7
registry.redhat.io/rhgs3/rhgs-gluster-block-prov-rhel7
registry.redhat.io/rhgs3/rhgs-s3-server-rhel7
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
nvidia/k8s-device-plugin:1.11
mirrorgooglecontainers/cuda-vector-add:v0.1
EOF
)

other_builder_images=$(cat << EOF
quay.io/coreos/flannel:v0.10.0-amd64
quay.io/coreos/flannel:v0.10.0-arm64
quay.io/coreos/flannel:v0.10.0-ppc64le
quay.io/coreos/flannel:v0.10.0-s390x
EOF
)