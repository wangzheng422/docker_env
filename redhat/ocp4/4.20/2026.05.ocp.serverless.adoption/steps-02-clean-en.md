# ROSA Spot Machine Pool Actual Lifecycle Retest Runbook (Clean)

| Field | Value |
|---|---|
| Test date | 2026-05-18 |
| Test objective | Verify whether EC2 instances created by a ROSA Spot machine pool are actually Spot instances |
| Execution location | `<bastion-host>` |
| ROSA cluster | `<cluster-name>`, Hosted CP |
| AWS Region | `<aws-region>` |
| AWS Account | `<aws-account-id>` |
| Related document | `solution-02-clean.md` |

---

## 1. Environment Login And Baseline Checks

```bash
$ sshpass -p '<bastion-password>' ssh -o StrictHostKeyChecking=no <bastion-user>@<bastion-host> 'hostname'
<bastion-internal-hostname>

$ rosa version
INFO: 1.2.53

$ oc version --client
Client Version: 4.20.22
Kustomize Version: v5.6.0

$ aws --version
aws-cli/2.34.48 Python/3.14.4 Linux/5.14.0-611.24.1.el9_7.x86_64 exe/x86_64.rhel.9

$ oc login https://<api-endpoint>:443 \
  -u <cluster-admin-user> -p '<cluster-admin-password>' \
  --insecure-skip-tls-verify
WARNING: Using insecure TLS client config. Setting this option is not supported!
Login successful.

$ oc version
Client Version: 4.20.22
Kustomize Version: v5.6.0
Server Version: 4.20.22
Kubernetes Version: v1.33.10

$ aws sts get-caller-identity
{
    "UserId": "<aws-user-id>",
    "Account": "<aws-account-id>",
    "Arn": "arn:aws:iam::<aws-account-id>:user/<aws-user>"
}

$ rosa list clusters
ID            NAME            STATE  TOPOLOGY
<cluster-id>  <cluster-name>  ready  Hosted CP

$ rosa list machinepools --cluster=<cluster-name>
ID       AUTOSCALING  REPLICAS  INSTANCE TYPE  LABELS    TAINTS    AVAILABILITY ZONE  SUBNET       DISK SIZE  VERSION  AUTOREPAIR
workers  No           2/2       m6a.xlarge                         <az>               <subnet-id>  300 GiB    4.20.22  Yes
```

---

## 2. Create Test Machine Pools

This test used two short machine pool names to stay within the ROSA HCP NodePool name length limit. The Spot-targeted pool was created with `--use-spot-instances`; the On-Demand pool was created without Spot options.

### 2.1 Create The Spot-Targeted And On-Demand Machine Pools

```bash
$ rosa create machinepool \
  --cluster=<cluster-name> \
  --name=<spot-machinepool> \
  --instance-type=m6a.xlarge \
  --min-replicas=0 \
  --max-replicas=1 \
  --enable-autoscaling \
  --labels="node-role.kubernetes.io/serverless=,capacity-type=spot" \
  --taints="serverless=true:NoSchedule" \
  --use-spot-instances \
  --spot-max-price=on-demand \
  --autorepair \
  -y
INFO: Machine pool '<spot-machinepool>' created successfully on hosted cluster '<cluster-name>'

$ rosa create machinepool \
  --cluster=<cluster-name> \
  --name=<on-demand-machinepool> \
  --instance-type=m6a.xlarge \
  --min-replicas=0 \
  --max-replicas=1 \
  --enable-autoscaling \
  --labels="node-role.kubernetes.io/serverless=,capacity-type=on-demand" \
  --taints="serverless=true:NoSchedule" \
  --autorepair \
  -y
INFO: Machine pool '<on-demand-machinepool>' created successfully on hosted cluster '<cluster-name>'

$ rosa list machinepools --cluster=<cluster-name>
ID                       AUTOSCALING  REPLICAS  INSTANCE TYPE  LABELS                                                          TAINTS
<on-demand-machinepool>  Yes          0/0-1     m6a.xlarge     capacity-type=on-demand, node-role.kubernetes.io/serverless=    serverless=true:NoSchedule
<spot-machinepool>       Yes          0/0-1     m6a.xlarge     capacity-type=spot, node-role.kubernetes.io/serverless=         serverless=true:NoSchedule
workers                  No           2/2       m6a.xlarge
```

---

## 3. Create Standard Deployments To Trigger Two Instances

```bash
$ oc new-project mp-lifecycle-test
Now using project "mp-lifecycle-test" on server "https://<api-endpoint>:443".

$ oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workload-spot
  namespace: mp-lifecycle-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: workload-spot
  template:
    metadata:
      labels:
        app: workload-spot
    spec:
      tolerations:
      - key: serverless
        operator: Equal
        value: "true"
        effect: NoSchedule
      nodeSelector:
        node-role.kubernetes.io/serverless: ""
        capacity-type: spot
      containers:
      - name: sleeper
        image: registry.access.redhat.com/ubi9/ubi-minimal:latest
        command: ["/bin/sh", "-c", "while true; do date; sleep 300; done"]
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workload-od
  namespace: mp-lifecycle-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: workload-od
  template:
    metadata:
      labels:
        app: workload-od
    spec:
      tolerations:
      - key: serverless
        operator: Equal
        value: "true"
        effect: NoSchedule
      nodeSelector:
        node-role.kubernetes.io/serverless: ""
        capacity-type: on-demand
      containers:
      - name: sleeper
        image: registry.access.redhat.com/ubi9/ubi-minimal:latest
        command: ["/bin/sh", "-c", "while true; do date; sleep 300; done"]
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
EOF
deployment.apps/workload-spot created
deployment.apps/workload-od created

$ oc get pods -n mp-lifecycle-test -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
workload-od-<pod-suffix>        0/1     Pending   0          0s    <none>   <none>   <none>           <none>
workload-spot-<pod-suffix>      0/1     Pending   0          0s    <none>   <none>   <none>           <none>
```

---

## 4. Observe Autoscaling

```bash
$ oc get events -n mp-lifecycle-test --sort-by=.lastTimestamp
LAST SEEN   TYPE      REASON              OBJECT                         MESSAGE
80s         Normal    TriggeredScaleUp    pod/workload-spot-<pod>        pod triggered scale-up: [{MachineDeployment/.../<cluster-name>-<spot-machinepool> 0->1 (max: 1)}]
62s         Normal    TriggeredScaleUp    pod/workload-od-<pod>          pod triggered scale-up: [{MachineDeployment/.../<cluster-name>-<on-demand-machinepool> 0->1 (max: 1)}]
```

The following polling output shows both Pods becoming `Running` and both test machine pools scaling from `0/0-1` to `1/0-1`:

```bash
--- poll <timestamp> ---
NAME                            READY   STATUS    RESTARTS   AGE     IP           NODE                  NOMINATED NODE   READINESS GATES
workload-od-<pod-suffix>        1/1     Running   0          4m31s   <pod-ip-1>   <on-demand-node>      <none>           <none>
workload-spot-<pod-suffix>      1/1     Running   0          4m31s   <pod-ip-2>   <spot-label-node>     <none>           <none>

ID                       AUTOSCALING  REPLICAS  INSTANCE TYPE  LABELS
<on-demand-machinepool>  Yes          1/0-1     m6a.xlarge     capacity-type=on-demand, node-role.kubernetes.io/serverless=
<spot-machinepool>       Yes          1/0-1     m6a.xlarge     capacity-type=spot, node-role.kubernetes.io/serverless=
```

---

## 5. AWS EC2 Lifecycle Evidence

### 5.1 Exact Pod, Node, And EC2 Mapping

```bash
$ oc get pods -n mp-lifecycle-test -o wide
NAME                            READY   STATUS    RESTARTS   AGE     IP           NODE                  NOMINATED NODE   READINESS GATES
workload-od-<pod-suffix>        1/1     Running   0          5m19s   <pod-ip-1>   <on-demand-node>      <none>           <none>
workload-spot-<pod-suffix>      1/1     Running   0          5m19s   <pod-ip-2>   <spot-label-node>     <none>           <none>

$ oc get nodes --selector=node-role.kubernetes.io/serverless= \
  -L capacity-type,hypershift.openshift.io/nodePool,node.kubernetes.io/instance-type
NAME                  STATUS   ROLES               AGE     VERSION    CAPACITY-TYPE   NODEPOOL                            INSTANCE-TYPE
<spot-label-node>     Ready    serverless,worker   2m15s   v1.33.11   spot            <cluster-name>-<spot-machinepool>     m6a.xlarge
<on-demand-node>      Ready    serverless,worker   111s    v1.33.11   on-demand       <cluster-name>-<on-demand-machinepool> m6a.xlarge
```

### 5.2 Final AWS Lifecycle Query

```bash
$ aws ec2 describe-instances \
  --region <aws-region> \
  --filters "Name=tag:api.openshift.com/nodepool-ocm,Values=<spot-machinepool>,<on-demand-machinepool>" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,NodePoolOCM:Tags[?Key==`api.openshift.com/nodepool-ocm`]|[0].Value,NodePoolHCP:Tags[?Key==`api.openshift.com/nodepool-hypershift`]|[0].Value,PrivateIp:PrivateIpAddress,State:State.Name,Type:InstanceType,Lifecycle:InstanceLifecycle,SpotRequest:SpotInstanceRequestId,LaunchTime:LaunchTime}' \
  --output json
[
    {
        "ID": "<spot-pool-instance-id>",
        "Name": "<cluster-name>-<spot-machinepool>-<suffix>",
        "NodePoolOCM": "<spot-machinepool>",
        "NodePoolHCP": "<cluster-name>-<spot-machinepool>",
        "PrivateIp": "<spot-node-private-ip>",
        "State": "running",
        "Type": "m6a.xlarge",
        "Lifecycle": null,
        "SpotRequest": null,
        "LaunchTime": "<timestamp>"
    },
    {
        "ID": "<on-demand-pool-instance-id>",
        "Name": "<cluster-name>-<on-demand-machinepool>-<suffix>",
        "NodePoolOCM": "<on-demand-machinepool>",
        "NodePoolHCP": "<cluster-name>-<on-demand-machinepool>",
        "PrivateIp": "<on-demand-node-private-ip>",
        "State": "running",
        "Type": "m6a.xlarge",
        "Lifecycle": null,
        "SpotRequest": null,
        "LaunchTime": "<timestamp>"
    }
]

$ aws ec2 describe-spot-instance-requests \
  --region <aws-region> \
  --filters "Name=instance-id,Values=<spot-pool-instance-id>,<on-demand-pool-instance-id>" \
  --query 'SpotInstanceRequests[].{SpotRequestId:SpotInstanceRequestId,InstanceId:InstanceId,State:State,Status:Status.Code,Type:Type}' \
  --output json
[]
```

Assessment:

- The EC2 instance for the Spot-targeted pool has `Lifecycle` set to `null`.
- The EC2 instance for the Spot-targeted pool has `SpotRequest` set to `null`.
- The reverse lookup for Spot instance requests returned an empty array.
- Therefore, this instance is actually On-Demand, not Spot.

---

## 6. Clean Up Test Workloads And Wait For Scale-Down

```bash
$ oc delete deployment workload-spot workload-od -n mp-lifecycle-test
deployment.apps "workload-spot" deleted
deployment.apps "workload-od" deleted

$ oc get pods -n mp-lifecycle-test -o wide
No resources found in mp-lifecycle-test namespace.
```

After both Deployments were deleted, the test waited for the cluster autoscaler to scale the two test machine pools back to zero. Key output:

```bash
--- scale-down T+907s <timestamp> ---
ID                       AUTOSCALING  REPLICAS  INSTANCE TYPE
<on-demand-machinepool>  Yes          1/0-1     m6a.xlarge
<spot-machinepool>       Yes          0/0-1     m6a.xlarge

--- scale-down T+939s <timestamp> ---
ID                       AUTOSCALING  REPLICAS  INSTANCE TYPE
<on-demand-machinepool>  Yes          0/0-1     m6a.xlarge
<spot-machinepool>       Yes          0/0-1     m6a.xlarge
```

---

## 7. Final State Verification

```bash
$ rosa list machinepools --cluster=<cluster-name>
ID                       AUTOSCALING  REPLICAS  INSTANCE TYPE  LABELS
<on-demand-machinepool>  Yes          0/0-1     m6a.xlarge     capacity-type=on-demand, node-role.kubernetes.io/serverless=
<spot-machinepool>       Yes          0/0-1     m6a.xlarge     capacity-type=spot, node-role.kubernetes.io/serverless=
workers                  No           2/2       m6a.xlarge

$ oc get pods -n mp-lifecycle-test
No resources found in mp-lifecycle-test namespace.

$ oc get nodes --selector=node-role.kubernetes.io/serverless=
No resources found

$ aws ec2 describe-instances \
  --region <aws-region> \
  --filters "Name=tag:api.openshift.com/nodepool-ocm,Values=<spot-machinepool>,<on-demand-machinepool>" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,NodePoolOCM:Tags[?Key==`api.openshift.com/nodepool-ocm`]|[0].Value,State:State.Name,Lifecycle:InstanceLifecycle,SpotRequest:SpotInstanceRequestId,PrivateIp:PrivateIpAddress}' \
  --output json
[
    {
        "ID": "<spot-pool-instance-id>",
        "Name": "<cluster-name>-<spot-machinepool>-<suffix>",
        "NodePoolOCM": "<spot-machinepool>",
        "State": "terminated",
        "Lifecycle": null,
        "SpotRequest": null,
        "PrivateIp": null
    },
    {
        "ID": "<on-demand-pool-instance-id>",
        "Name": "<cluster-name>-<on-demand-machinepool>-<suffix>",
        "NodePoolOCM": "<on-demand-machinepool>",
        "State": "terminated",
        "Lifecycle": null,
        "SpotRequest": null,
        "PrivateIp": null
    }
]
```

---

## 8. Conclusion

1. Two machine pools were created: one with `--use-spot-instances`, and one standard On-Demand pool.
2. Each machine pool created one EC2 instance, and standard Deployments were used to run test Pods on each instance.
3. Kubernetes scheduling behaved correctly: `workload-spot` ran on the `capacity-type=spot` node, and `workload-od` ran on the `capacity-type=on-demand` node.
4. At the AWS billing lifecycle layer, both instances showed `InstanceLifecycle=null` and `SpotInstanceRequestId=null`.
5. Therefore, the instance created by the Spot-targeted pool was actually On-Demand, not Spot.
6. The original documentation must be corrected: ROSA/OpenShift labels must not be treated as proof of Spot billing.
7. After the test, both test machine pools were retained and scaled back to `0/0-1`; the test instances were terminated.
