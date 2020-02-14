```bash
# GUID, is: 2192
export GUID=2192

ssh -tt zhengwan-redhat.com@bastion.f93a.sandbox744.opentlc.com "bash -c byobu"

ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export OCP_RELEASE" line="export OCP_RELEASE=4.2.12"'

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export OCP_RELEASE" line="export OCP_RELEASE=4.3.2"'

source $HOME/.bashrc

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz

sudo tar xzf openshift-client-linux-$OCP_RELEASE.tar.gz -C /usr/local/sbin/ oc kubectl

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz

sudo tar xzf openshift-install-linux-$OCP_RELEASE.tar.gz -C /usr/local/sbin/ openshift-install

which oc
which openshift-install

oc completion bash | sudo tee /etc/bash_completion.d/openshift > /dev/null

mkdir ~/install
cd install

openshift-install create install-config --dir $HOME/install
```
edit install-config.yaml
```yaml
apiVersion: v1
baseDomain: sandbox1572.opentlc.com
compute:
- hyperthreading: Enabled
  name: worker
  platform:
    aws:
      type: m5.xlarge
  replicas: 2
controlPlane:
  hyperthreading: Enabled
  name: master
  platform: 
    aws:
      type: m5.xlarge
  replicas: 3
metadata:
  creationTimestamp: null
  name: "cluster2192"
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineCIDR: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: us-west-2
pullSecret: '{*****************}'
sshKey: |
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCi/8RUbaQKrA1O3pn3g0QvMVQEEx88rhgJJoD5MOeMMP3xtGuiLkTC9xWxrz5eA3tkb+RlWozQ4FlU6sFiFXM3Mu4aRRfdi+1Km9c3dTUnG9cnu0EjSPhRs2zIP/nrSTe/HYn5qMGLchof4ol1BJIMTQFKrgDs21GcIS6dp9v+ckKQvrR6lU1Q81v1H1QO5u4ZpggLc9nhfS2suueO7P1lZ5tIhiM0lm1A3ry9EtoIjHxVhNsBQMdQCth9h0B/GUIP2XCqtw/PgWpLWid995dNMD2XNLuQsx8POrVdS9vnZ+JVrzIXMfiFw8Y+OYGudX5ZZFoibfVubX8/Vcfaizf zhengwan-redhat.com@clientvm.f93a.internal

```
```bash
openshift-install create cluster --dir=$HOME/install --log-level=debug

openshift-install destroy cluster --dir=$HOME/install --log-level=debug

# openshift-install wait-for install-complete --dir $HOME/install
# openshift-install destroy cluster  --dir=$HOME/install  --log-level=debug

ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export KUBECONFIG" line="export KUBECONFIG=$HOME/install/auth/kubeconfig"'
source $HOME/.bashrc

oc get machineset -n openshift-machine-api
# on web console, label machineset, node, to infra
# on web console, change machineset to m5.large, and create machine

oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec":{"nodePlacement":{"nodeSelector": {"matchLabels":{"node-role.kubernetes.io/infra":""}}}}}'

oc get nodes|grep infra

oc patch configs.imageregistry.operator.openshift.io/cluster -n openshift-image-registry --type=merge --patch '{"spec":{"nodeSelector":{"node-role.kubernetes.io/infra":""}}}'

oc get pod -o wide -n openshift-image-registry --sort-by=".spec.nodeName"

cat <<EOF > $HOME/monitoring-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |+
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
EOF

oc create -f $HOME/monitoring-cm.yaml -n openshift-monitoring

watch oc get pods -n openshift-monitoring -o wide --sort-by=".spec.nodeName"

mkdir $HOME/cluster-logging

cat << EOF >$HOME/cluster-logging/es_namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-operators-redhat
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-logging: "true"
    openshift.io/cluster-monitoring: "true"
EOF

oc create -f $HOME/cluster-logging/es_namespace.yaml

cat << EOF >$HOME/cluster-logging/cl_namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-logging
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-logging: "true"
    openshift.io/cluster-monitoring: "true"
EOF

oc create -f $HOME/cluster-logging/cl_namespace.yaml

cat << EOF >$HOME/cluster-logging/operator_group.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-operators-redhat
  namespace: openshift-operators-redhat
spec: {}
EOF

oc create -f $HOME/cluster-logging/operator_group.yaml

oc get packagemanifest elasticsearch-operator -n openshift-marketplace -o jsonpath='{.status.channels[].name}'

cat << EOF >$HOME/cluster-logging/subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  generateName: "elasticsearch-"
  namespace: "openshift-operators-redhat"
spec:
  channel: "4.2"
  installPlanApproval: "Automatic"
  source: "redhat-operators"
  sourceNamespace: "openshift-marketplace"
  name: "elasticsearch-operator"
EOF

oc create -f $HOME/cluster-logging/subscription.yaml

cat << EOF >$HOME/cluster-logging/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus-k8s
  namespace: openshift-operators-redhat
rules:
- apiGroups:
  - ""
  resources:
  - services
  - endpoints
  - pods
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus-k8s
  namespace: openshift-operators-redhat
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: openshift-operators-redhat
EOF

oc create -f $HOME/cluster-logging/rbac.yaml

oc get pod -n openshift-operators-redhat -o wide

oc logs elasticsearch-operator-646cd66f48-dzzkp -n openshift-operators-redhat

oc whoami --show-console
# create Cluster Logging operator in openshift-logging project

oc get pod -n openshift-logging -o wide

oc logs cluster-logging-operator-557b5b8b4-ql5s7 -n openshift-logging

```
```yaml
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  managementState: Managed
  logStore:
    type: elasticsearch
    elasticsearch:
      resources:
        limits:
          memory: 6Gi
        requests:
          memory: 4Gi
          cpu: 500m
      nodeCount: 2
      nodeSelector:
        node-role.kubernetes.io/logging: ""
      redundancyPolicy: SingleRedundancy
      storage:
        storageClassName: gp2
        size: 20G
      tolerations:
      - key: logging
        value: reserved
        effect: NoSchedule
      - key: logging
        value: reserved
        effect: NoExecute
  visualization:
    type: kibana
    kibana:
      replicas: 1
      nodeSelector:
        node-role.kubernetes.io/logging: ""
      tolerations:
      - key: logging
        value: reserved
        effect: NoSchedule
      - key: logging
        value: reserved
        effect: NoExecute
  curation:
    type: curator
    curator:
      schedule: 30 3 * * *
      nodeSelector:
        node-role.kubernetes.io/logging: ""
      tolerations:
      - key: logging
        value: reserved
        effect: NoSchedule
      - key: logging
        value: reserved
        effect: NoExecute
  collection:
    logs:
      type: fluentd
      fluentd:
        tolerations:
        - effect: NoSchedule
          key: infra
          value: reserved
        - effect: NoExecute
          key: infra
          value: reserved
        - key: logging
          value: reserved
          effect: NoSchedule
        - key: logging
          value: reserved
          effect: NoExecute
```
```bash
oc get pod -n openshift-logging -o json | jq -r '.items[].spec.containers[].image'

oc adm create-bootstrap-project-template -o yaml > template.yaml

oc create -f template.yaml -n openshift-config

oc apply -f template.yaml -n openshift-config

oc edit project.config.openshift.io/cluster
```
```yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  creationTimestamp: null
  name: project-request
objects:
- apiVersion: project.openshift.io/v1
  kind: Project
  metadata:
    annotations:
      openshift.io/description: ${PROJECT_DESCRIPTION}
      openshift.io/display-name: ${PROJECT_DISPLAYNAME}
      openshift.io/requester: ${PROJECT_REQUESTING_USER}
    creationTimestamp: null
    name: ${PROJECT_NAME}
  spec: {}
  status: {}
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    creationTimestamp: null
    name: admin
    namespace: ${PROJECT_NAME}
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: admin
  subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: ${PROJECT_ADMIN_USER}
- apiVersion: v1
  kind: LimitRange
  metadata:
    name: project-limits
  spec:
    limits:
    - type: Pod
      max:
        cpu: 1
        memory: 1Gi
      min:
        cpu: 500m
        memory: 500Mi
    - type: Container
      max:
        cpu: 1
        memory: 1Gi
      min:
        cpu: 500m
        memory: 500Mi
      default:
        cpu: 500m
        memory: 500Mi
- apiVersion: v1
  kind: ResourceQuota
  metadata:
    name: project-quota
  spec:
    hard:
      pods: "10" 
      requests.cpu: "4" 
      requests.memory: 8Gi 
      limits.cpu: "6" 
      limits.memory: 16Gi 
      requests.storage: "20G" 
- kind: NetworkPolicy
  apiVersion: networking.k8s.io/v1
  metadata:
    name: allow-same-namespace
  spec:
    podSelector: {}
    ingress:
    - from:
      - podSelector: {}
- apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-from-openshift-ingress
  spec:
    podSelector: {}
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            network.openshift.io/policy-group: ingress
parameters:
- name: PROJECT_NAME
- name: PROJECT_DISPLAYNAME
- name: PROJECT_DESCRIPTION
- name: PROJECT_ADMIN_USER
- name: PROJECT_REQUESTING_USER

```
```yaml
apiVersion: config.openshift.io/v1
kind: Project
metadata:
  annotations:
    release.openshift.io/create-only: 'true'
  creationTimestamp: '2019-12-06T04:19:34Z'
  generation: 1
  name: cluster
  resourceVersion: '1784'
  selfLink: /apis/config.openshift.io/v1/projects/cluster
  uid: 9ba5a292-17df-11ea-9657-020c51918eb8
spec:
  projectRequestTemplate:
    name: project-request
```
```bash
cd $HOME
touch $HOME/htpasswd
htpasswd -Bb $HOME/htpasswd john openshift4
htpasswd -Bb $HOME/htpasswd paul openshift4
htpasswd -Bb $HOME/htpasswd ringo openshift4
htpasswd -Bb $HOME/htpasswd george openshift4
htpasswd -Bb $HOME/htpasswd pete openshift4

oc create secret generic htpasswd --from-file=$HOME/htpasswd -n openshift-config

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

watch oc get pod -n openshift-authentication

oc login -u john -p openshift4 $(oc whoami --show-server)
oc login -u paul -p openshift4 $(oc whoami --show-server)
oc login -u ringo -p openshift4 $(oc whoami --show-server)
oc login -u george -p openshift4 $(oc whoami --show-server)
oc login -u pete -p openshift4 $(oc whoami --show-server)

oc login -u system:admin

oc delete secret  htpasswd -n openshift-config
oc create secret generic htpasswd --from-file=$HOME/htpasswd -n openshift-config

oc adm groups new lab-cluster-admins john

oc adm policy add-cluster-role-to-group cluster-admin lab-cluster-admins --rolebinding-name=lab-cluster-admins

oc adm policy add-cluster-role-to-user cluster-admin  john

grade_lab ocp_adv_infra hw
```