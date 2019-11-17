
```bash

ssh -i ~/.ssh/id_rsa.redhat -tt zhengwan-redhat.com@bastion.53eb.example.opentlc.com tmux

ansible localhost,all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

git clone https://github.com/coreos/etcd-operator.git
cd $HOME/etcd-operator
oc new-project etcd-operators
./example/rbac/create_role.sh --namespace=etcd-operators
oc describe clusterrole etcd-operator
oc create -f ./example/deployment.yaml
oc logs etcd-operator-649dbdb5cb-b6rsg

oc get crds
oc describe crd etcdclusters.etcd.database.coreos.com
oc get etcdclusters

oc create -f ./example/example-etcd-cluster.yaml
watch oc get pods
oc get etcdclusters

vi ./example/example-etcd-cluster.yaml
oc replace -f ./example/example-etcd-cluster.yaml

oc get events|grep EtcdCluster
oc get services

ssh master1.$GUID.internal
wget https://github.com/etcd-io/etcd/releases/download/v3.2.28/etcd-v3.2.28-linux-amd64.tar.gz
tar zvxf etcd-v3.2.28-linux-amd64.tar.gz
./etcdctl --endpoints http://172.30.98.55:2379 cluster-health
```
```
member f852eac73d05e3b is healthy: got healthy result from http://example-etcd-cluster-cv8zbqf5ql.example-etcd-cluster.etcd-operators.svc:2379
member 68920a7d38ac698f is healthy: got healthy result from http://example-etcd-cluster-cx7v2hjq9t.example-etcd-cluster.etcd-operators.svc:2379
member 9b14219c9c9f0a85 is healthy: got healthy result from http://example-etcd-cluster-wg9p9tmfr6.example-etcd-cluster.etcd-operators.svc:2379
member cebc444200e78310 is healthy: got healthy result from http://example-etcd-cluster-jmt54dbzcn.example-etcd-cluster.etcd-operators.svc:2379
member d66f4d2a02f7acaf is healthy: got healthy result from http://example-etcd-cluster-vpbg6k58vd.example-etcd-cluster.etcd-operators.svc:2379
cluster is healthy
```
```bash
./etcdctl --endpoints http://172.30.98.55:2379 set foo 'Hello world!'
# Hello world!
./etcdctl --endpoints http://172.30.98.55:2379 get foo
# Hello world!

oc delete etcdcluster example-etcd-cluster
watch oc get pods

cd $HOME/etcd-operator
oc delete -f example/deployment.yaml
oc delete clusterrole etcd-operator
oc delete clusterrolebinding etcd-operator
oc delete crd etcdclusters.etcd.database.coreos.com

#########################
## next
ansible localhost,all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

wget https://github.com/operator-framework/operator-sdk/releases/download/v0.6.0/operator-sdk-v0.6.0-x86_64-linux-gnu -O /usr/local/bin/operator-sdk
chmod +x /usr/local/bin/operator-sdk

export PATH=$PATH:/usr/local/bin
echo "export PATH=$PATH:/usr/local/bin" >> $HOME/.bashrc

cd $HOME
git clone https://github.com/redhat-gpte-devopsautomation/ansible-operator-roles
cd ansible-operator-roles
git checkout v0.6.0
cd $HOME

cat $HOME/ansible-operator-roles/playbooks/gogs.yaml
# Postgresql-ocp Tasks File
cat $HOME/ansible-operator-roles/roles/postgresql-ocp/tasks/main.yml
# Postgresql-ocp Variable defaults
cat $HOME/ansible-operator-roles/roles/postgresql-ocp/defaults/main.yml

# Gogs-ocp Tasks File
cat $HOME/ansible-operator-roles/roles/gogs-ocp/tasks/main.yml
# Gogs-ocp Variable defaults
cat $HOME/ansible-operator-roles/roles/gogs-ocp/defaults/main.yml

cd $HOME
operator-sdk new gogs-operator --api-version=gpte.opentlc.com/v1alpha1 --kind=Gogs --type=ansible --generate-playbook --skip-git-init

cd $HOME/gogs-operator
rm -rf roles playbook.yml
mkdir roles
cp -R $HOME/ansible-operator-roles/roles/postgresql-ocp ./roles
cp -R $HOME/ansible-operator-roles/roles/gogs-ocp ./roles
cp $HOME/ansible-operator-roles/playbooks/gogs.yaml ./playbook.yml

cat ./watches.yaml
cat build/Dockerfile

yum -y install docker
systemctl enable docker
systemctl start docker

export QUAY_ID=zhengwan
docker login -u ${QUAY_ID} quay.io

cd $HOME/gogs-operator
operator-sdk build quay.io/${QUAY_ID}/gogs-operator:v0.0.1

docker push quay.io/${QUAY_ID}/gogs-operator:v0.0.1

# quay.io/zhengwan/gogs-operator:v0.0.1
vim ./deploy/operator.yaml
```
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gogs-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      name: gogs-operator
  template:
    metadata:
      labels:
        name: gogs-operator
    spec:
      serviceAccountName: gogs-operator
      containers:
        - name: ansible
          command:
          - /usr/local/bin/ao-logs
          - /tmp/ansible-operator/runner
          - stdout
          # Replace this with the built image name
          image: quay.io/<your quay id>/gogs-operator:v0.0.1
          imagePullPolicy: IfNotPresent
          volumeMounts:
          - mountPath: /tmp/ansible-operator/runner
            name: runner
            readOnly: true
        - name: operator
          # Replace this with the built image name
          image: quay.io/<your quay id>/gogs-operator:v0.0.1
          imagePullPolicy: IfNotPresent
          volumeMounts:
          - mountPath: /tmp/ansible-operator/runner
            name: runner
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "gogs-operator"
      volumes:
        - name: runner
          emptyDir: {}
```
```bash
cat ./deploy/crds/gpte_v1alpha1_gogs_crd.yaml

echo '---
apiVersion: authorization.openshift.io/v1
kind: ClusterRole
metadata:
  labels:
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
  name: gogs-admin-rules
rules:
- apiGroups:
   - apps
  resources:
  - deployments/finalizers
  verbs:
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - gpte.opentlc.com
  resources:
  - gogs
  - gogs/status
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch' | oc create -f -

oc login -u andrew -p r3dh4t1! https://master.$GUID.example.opentlc.com
oc new-project gogs-operator --display-name="Gogs"
oc create -f ./deploy/service_account.yaml

cat << EOF > ./deploy/role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gogs-operator
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - services
  - endpoints
  - persistentvolumeclaims
  - configmaps
  - secrets
  verbs:
  - create
  - update
  - delete
  - get
  - list
  - watch
  - patch
- apiGroups:
  - route.openshift.io
  resources:
  - routes
  verbs:
  - create
  - update
  - delete
  - get
  - list
  - watch
  - patch
- apiGroups:
  - apps
  resources:
  - deployments
  - deployments/finalizers
  verbs:
  - get
  - update
  - delete
  - get
  - list
  - watch
  - patch
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
- apiGroups:
  - apps
  resourceNames:
  - gogs-operator
  resources:
  - deployments/finalizers
  verbs:
  - update
- apiGroups:
  - gpte.opentlc.com
  resources:
  - gogs
  - gogs/status
  verbs:
  - create
  - update
  - delete
  - get
  - list
  - watch
  - patch
EOF

oc create -f ./deploy/role.yaml
oc create -f ./deploy/role_binding.yaml

oc create -f ./deploy/operator.yaml

watch oc get pod

oc logs -c operator gogs-operator-7cd686b8f6-24pnv
```
```
{"level":"info","ts":1573964270.3191545,"logger":"cmd","msg":"Go Version: go1.10.3"}
{"level":"info","ts":1573964270.3192976,"logger":"cmd","msg":"Go OS/Arch: linux/amd64"}
{"level":"info","ts":1573964270.3193405,"logger":"cmd","msg":"Version of operator-sdk: v0.6.0"}
{"level":"info","ts":1573964270.3194144,"logger":"cmd","msg":"Watching namespace.","Namespace":"gogs-operator"}
{"level":"info","ts":1573964270.375413,"logger":"leader","msg":"Trying to become the leader."}
{"level":"info","ts":1573964270.426274,"logger":"leader","msg":"No pre-existing lock was found."}
{"level":"info","ts":1573964270.4295316,"logger":"leader","msg":"Became the leader."}
{"level":"info","ts":1573964270.4311666,"logger":"proxy","msg":"Starting to serve","Address":"127.0.0.1:8888"}
{"level":"info","ts":1573964270.4315948,"logger":"manager","msg":"Using default value for workers 1"}
{"level":"info","ts":1573964270.4316196,"logger":"ansible-controller","msg":"Watching resource","Options.Group":"gpte.opentlc.com","Options.Version":"v1alpha1","Options.Kind":"Gogs"}
{"level":"info","ts":1573964270.4319053,"logger":"kubebuilder.controller","msg":"Starting EventSource","controller":"gogs-controller","source":"kind source: gpte.opentlc.com/v1alpha1, Kind=Gogs"}
{"level":"info","ts":1573964270.532302,"logger":"kubebuilder.controller","msg":"Starting Controller","controller":"gogs-controller"}
{"level":"info","ts":1573964270.632624,"logger":"kubebuilder.controller","msg":"Starting workers","controller":"gogs-controller","worker count":1}
```
```bash
echo "apiVersion: gpte.opentlc.com/v1alpha1
kind: Gogs
metadata:
  name: gogs-server
spec:
  postgresqlVolumeSize: 4Gi
  gogsVolumeSize: 4Gi
  gogsSsl: True" > $HOME/gogs-operator/gogs-server.yaml

oc create -f $HOME/gogs-operator/gogs-server.yaml

oc logs -c operator -f gogs-operator-7cd686b8f6-24pnv
```
```
{"level":"info","ts":1573964443.3779342,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Set Gogs Service to present"}
{"level":"info","ts":1573964444.1787612,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Set Gogs Route to present"}
{"level":"info","ts":1573964445.0577378,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Set Gogs PersistentVolumeClaim to present"}
{"level":"info","ts":1573964445.856149,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Set Gogs ConfigMap to present"}
{"level":"info","ts":1573964446.668711,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Set Gogs Pod to present"}
{"level":"info","ts":1573964447.4395597,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Pause to wait for pod to be in the system"}
{"level":"info","ts":1573964452.4763825,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Verify that the Gogs Pod is running"}
{"level":"info","ts":1573964453.265382,"logger":"logging_event_handler","msg":"[playbook task]","name":"gogs-server","namespace":"gogs-operator","gvk":"gpte.opentlc.com/v1alpha1, Kind=Gogs","event_type":"playbook_on_task_start","job":"4546760500381000397","EventData.Name":"./roles/gogs-ocp : Verify that the Gogs Pod is ready"}
{"level":"info","ts":1573964454.1843622,"logger":"runner","msg":"Ansible-runner exited successfully","job":"4546760500381000397","name":"gogs-server","namespace":"gogs-operator"}
```
```bash
oc logs -c ansible -f gogs-operator-7cd686b8f6-24pnv
```
```
TASK [./roles/gogs-ocp : Verify that the Gogs Pod is ready] ********************
task path: /opt/ansible/roles/gogs-ocp/tasks/main.yml:149
ok: [localhost] => {"attempts": 1, "changed": false, "method": "patch", "result": {"apiVersion": "v1", "kind": "Pod", "metadata": {"annotations": {"openshift.io/scc": "restricted"}, "creationTimestamp": "2019-11-17T04:20:02Z", "labels": {"app": "gogs-gogs-server"}, "name": "gogs-gogs-server", "namespace": "gogs-operator", "ownerReferences": [{"apiVersion": "gpte.opentlc.com/v1alpha1", "kind": "Gogs", "name": "gogs-server", "uid": "6912ef44-08f1-11ea-9199-062b1fd05829"}], "resourceVersion": "90772", "selfLink": "/api/v1/namespaces/gogs-operator/pods/gogs-gogs-server", "uid": "86807ce3-08f1-11ea-9199-062b1fd05829"}, "spec": {"containers": [{"image": "docker.io/wkulhanek/gogs:latest", "imagePullPolicy": "IfNotPresent", "livenessProbe": {"failureThreshold": 3, "httpGet": {"path": "/", "port": 3000, "scheme": "HTTP"}, "initialDelaySeconds": 3, "periodSeconds": 10, "successThreshold": 1, "timeoutSeconds": 1}, "name": "gogs", "ports": [{"containerPort": 3000, "protocol": "TCP"}], "readinessProbe": {"failureThreshold": 3, "httpGet": {"path": "/", "port": 3000, "scheme": "HTTP"}, "initialDelaySeconds": 3, "periodSeconds": 20, "successThreshold": 1, "timeoutSeconds": 1}, "resources": {"limits": {"cpu": "500m", "memory": "512Mi"}, "requests": {"cpu": "500m", "memory": "512Mi"}}, "securityContext": {"capabilities": {"drop": ["KILL", "MKNOD", "SETGID", "SETUID"]}, "runAsUser": 1000080000}, "terminationMessagePath": "/dev/termination-log", "terminationMessagePolicy": "File", "volumeMounts": [{"mountPath": "/data", "name": "gogs-data"}, {"mountPath": "/opt/gogs/custom/conf", "name": "gogs-config"}, {"mountPath": "/var/run/secrets/kubernetes.io/serviceaccount", "name": "default-token-6s595", "readOnly": true}]}], "dnsPolicy": "ClusterFirst", "imagePullSecrets": [{"name": "default-dockercfg-w72bg"}], "nodeName": "node1.53eb.internal", "nodeSelector": {"node-role.kubernetes.io/compute": "true"}, "priority": 0, "restartPolicy": "Always", "schedulerName": "default-scheduler", "securityContext": {"fsGroup": 1000080000, "seLinuxOptions": {"level": "s0:c9,c4"}}, "serviceAccount": "default", "serviceAccountName": "default", "terminationGracePeriodSeconds": 30, "tolerations": [{"effect": "NoSchedule", "key": "node.kubernetes.io/memory-pressure", "operator": "Exists"}], "volumes": [{"name": "gogs-data", "persistentVolumeClaim": {"claimName": "gogs-gogs-server-pvc"}}, {"configMap": {"defaultMode": 420, "items": [{"key": "app.ini", "path": "app.ini"}], "name": "gogs-gogs-server-config"}, "name": "gogs-config"}, {"name": "default-token-6s595", "secret": {"defaultMode": 420, "secretName": "default-token-6s595"}}]}, "status": {"conditions": [{"lastProbeTime": null, "lastTransitionTime": "2019-11-17T04:20:02Z", "status": "True", "type": "Initialized"}, {"lastProbeTime": null, "lastTransitionTime": "2019-11-17T04:20:28Z", "status": "True", "type": "Ready"}, {"lastProbeTime": null, "lastTransitionTime": null, "status": "True", "type": "ContainersReady"}, {"lastProbeTime": null, "lastTransitionTime": "2019-11-17T04:20:02Z", "status": "True", "type": "PodScheduled"}], "containerStatuses": [{"containerID": "docker://2104395654a84819a8723bca30389a4057da600e2993e919d92983c09dc0b71d", "image": "docker.io/wkulhanek/gogs:latest", "imageID": "docker-pullable://docker.io/wkulhanek/gogs@sha256:4d2236007ea8f256bec5141d23673bde54f903a0b3a7fcc5c5575278c65c73bc", "lastState": {}, "name": "gogs", "ready": true, "restartCount": 0, "state": {"running": {"startedAt": "2019-11-17T04:20:14Z"}}}], "hostIP": "192.168.0.243", "phase": "Running", "podIP": "10.1.4.17", "qosClass": "Guaranteed", "startTime": "2019-11-17T04:20:02Z"}}}
META: ran handlers
META: ran handlers

PLAY RECAP *********************************************************************
localhost                  : ok=18   changed=0    unreachable=0    failed=0
```
```bash
oc get gogs
oc describe gogs gogs-server
```
```
Name:         gogs-server
Namespace:    gogs-operator
Labels:       <none>
Annotations:  <none>
API Version:  gpte.opentlc.com/v1alpha1
Kind:         Gogs
Metadata:
  Creation Timestamp:  2019-11-17T04:19:13Z
  Generation:          1
  Resource Version:    90956
  Self Link:           /apis/gpte.opentlc.com/v1alpha1/namespaces/gogs-operator/gogs/gogs-server
  UID:                 6912ef44-08f1-11ea-9199-062b1fd05829
Spec:
  Gogs Ssl:                true
  Gogs Volume Size:        4Gi
  Postgresql Volume Size:  4Gi
Status:
  Conditions:
    Ansible Result:
      Changed:             0
      Completion:          2019-11-17T04:21:53.998948
      Failures:            0
      Ok:                  18
      Skipped:             0
    Last Transition Time:  2019-11-17T04:19:13Z
    Message:               Awaiting next reconciliation
    Reason:                Successful
    Status:                True
    Type:                  Running
Events:                    <none>
```
```bash
oc get route

echo "apiVersion: gpte.opentlc.com/v1alpha1
kind: Gogs
metadata:
  name: another-gogs
spec:
  postgresqlVolumeSize: 4Gi
  gogsVolumeSize: 4Gi
  gogsSsl: False" > $HOME/gogs-operator/gogs-server-2.yaml

oc create -f $HOME/gogs-operator/gogs-server-2.yaml
watch oc get pod

oc get pod postgresql-gogs-gogs-server -o yaml

oc delete gogs gogs-server
oc delete gogs another-gogs

oc delete deployment gogs-operator
oc delete rolebinding gogs-operator
oc delete role gogs-operator
oc delete sa gogs-operator

oc delete project gogs-operator

oc login -u system:admin
oc delete clusterrole gogs-admin-rules
oc delete crd gogs.gpte.opentlc.com


```