# RHCL Three-Cluster / Two-Domain GLB E2E Report

| Field | Value |
|---|---|
| Date | 2026-06-18 |
| Author | George Zheng Wang (SAA), zhengwan@redhat.com |
| Audience | Customer senior technical review |
| Scope | Red Hat Connectivity Link / Kuadrant DNS based global load balancing validation |
| Environment | Three single-node OpenShift clusters on AWS EC2 helper |
| Helper users | `sno`, `sno2`, `sno3` |
| Cluster groups | `demo-01`, `demo-02`, `demo-03` |
| Tested domains | `glb-a.kuadrant.wzhlab.top`, `glb-b.kuadrant.wzhlab.top` |
| Baseline domain | `glb.kuadrant.wzhlab.top` |

## 1. Executive Conclusion

This E2E validation proves that RHCL can publish two independent application hostnames from three OpenShift clusters and can remove a failed cluster from DNS answers after application failure.

The validated design is:

```text
Per hostname:
  Gateway + HTTPRoute + DNSPolicy
  -> DNSRecord
  -> DNSHealthCheckProbe
  -> Kuadrant CoreDNS answer
  -> Gateway VIP
  -> application Service and Pod

For failover:
  App failure
  -> DNSHealthCheckProbe becomes unhealthy
  -> controller/test logic removes the cluster group from that hostname active-groups TXT
  -> CoreDNS/RHCL converges
  -> bad Gateway VIP disappears from DNS answers
```

The most important conclusion is:

```text
DNSPolicy.weight is useful for weighted distribution inside a bucket.
active-groups is the reliable include/exclude switch for failover.
DNSPolicy.weight=0 alone was not reliable enough as the only failover switch in this lab.
```

From an Avi ALB/GSLB replacement perspective:

| Avi capability area | RHCL PoC result | Replacement conclusion |
|---|---|---|
| Active/active DNS publication across clusters | Validated | Can replace for DNS-based multi-cluster active/active publication. |
| Weighted distribution among clusters in one region/bucket | Validated | Can replace this part. |
| Health-based removal of failed app endpoint | Validated with active-groups convergence | Can replace with controller automation and explicit convergence SLA. |
| Multiple independent FQDNs with different policy | Validated | Can replace with per-hostname Gateway/DNSPolicy/active-groups. |
| Multi-region survival when one site fails | Validated with caveat | Can provide survival/failover, but not full Avi GSLB policy equivalence. |
| Closest data center / best-performing data center | Not validated / not native in this PoC | Not a direct replacement without additional geo, ECS, latency, or upstream DNS/GSLB layer. |
| Avi-style GSLB leader/site federation | Not provided by this PoC | Requires separate controller/control-plane design. |

## 2. Three-Cluster Topology

| Cluster | Helper user | RHCL group | CoreDNS LB VIP | Baseline Gateway VIP | Domain A VIP | Domain B VIP |
|---|---|---|---:|---:|---:|---:|
| demo-01 | `sno` | `demo-01` | `192.168.99.210` | `192.168.99.211` | `192.168.99.212` | `192.168.99.213` |
| demo-02 | `sno2` | `demo-02` | `192.168.99.230` | `192.168.99.221` | `192.168.99.220` | `192.168.99.222` |
| demo-03 | `sno3` | `demo-03` | `192.168.99.240` | `192.168.99.241` | `192.168.99.242` | `192.168.99.243` |

The upstream DNS model simulated an Infoblox-style delegated subdomain:

```text
Parent DNS delegates kuadrant.wzhlab.top to the OpenShift-hosted Kuadrant CoreDNS VIPs.
Kuadrant CoreDNS serves RHCL-generated records for application hostnames.
Each OpenShift Gateway VIP is the actual HTTP entry point for the application.
```

## 3. Operator Installation

The same operator installation pattern is applied to all three clusters.

### 3.1 cert-manager, RHCL, and MetalLB operators

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-operator
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cert-manager-operator
  namespace: cert-manager-operator
spec:
  targetNamespaces:
    - cert-manager-operator
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-cert-manager-operator
  namespace: cert-manager-operator
spec:
  channel: stable-v1.18
  installPlanApproval: Automatic
  name: openshift-cert-manager-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: v1
kind: Namespace
metadata:
  name: kuadrant-system
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: kuadrant-system
  namespace: kuadrant-system
spec:
  targetNamespaces:
    - kuadrant-system
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhcl-operator
  namespace: kuadrant-system
spec:
  channel: stable
  installPlanApproval: Automatic
  name: rhcl-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: metallb-system
  namespace: metallb-system
spec:
  targetNamespaces:
    - metallb-system
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: metallb-operator
  namespace: metallb-system
spec:
  channel: stable
  installPlanApproval: Automatic
  name: metallb-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

Apply to all clusters:

```bash
su - sno  -c 'oc apply -f /tmp/rhcl-operators.yaml'
su - sno2 -c 'oc apply -f /tmp/rhcl-operators.yaml'
su - sno3 -c 'oc apply -f /tmp/rhcl-operators.yaml'
```

Lab-specific OLM correction that was required in this environment:

```bash
for user in sno sno2 sno3; do
  su - "${user}" -c 'oc patch operatorgroup kuadrant-system -n kuadrant-system --type=json -p='\''[{"op":"remove","path":"/spec/targetNamespaces"}]'\'''
  su - "${user}" -c 'oc patch operatorgroup metallb-system -n metallb-system --type=json -p='\''[{"op":"remove","path":"/spec/targetNamespaces"}]'\'''
done
```

This correction is not a GLB feature. It is an operator install-mode compatibility correction for this lab.

## 4. RHCL Core Configuration

### 4.1 GatewayClass and Kuadrant CR

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: openshift-default
spec:
  controllerName: openshift.io/gateway-controller/v1
---
apiVersion: kuadrant.io/v1beta1
kind: Kuadrant
metadata:
  name: kuadrant
  namespace: kuadrant-system
```

Apply and wait:

```bash
for user in sno sno2 sno3; do
  su - "${user}" -c 'oc apply -f /tmp/rhcl-core.yaml'
  su - "${user}" -c 'oc wait kuadrant/kuadrant -n kuadrant-system --for=condition=Ready=true --timeout=600s'
done
```

### 4.2 RHCL DNS Operator identity per cluster

Each DNS Operator must have a stable `GROUP`. This group is later used in DNSRecord ownership and active-groups membership.

demo-01:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dns-operator-controller-env
  namespace: kuadrant-system
data:
  DELEGATION_ROLE: primary
  GROUP: demo-01
  MAX_REQUEUE_TIME: 30s
```

demo-02 and demo-03 use the same ConfigMap with:

```text
demo-02: GROUP=demo-02
demo-03: GROUP=demo-03
```

After changing this ConfigMap, restart DNS Operator pods:

```bash
su - sno  -c 'oc delete pod -n kuadrant-system -l app.kubernetes.io/name=dns-operator --ignore-not-found'
su - sno2 -c 'oc delete pod -n kuadrant-system -l app.kubernetes.io/name=dns-operator --ignore-not-found'
su - sno3 -c 'oc delete pod -n kuadrant-system -l app.kubernetes.io/name=dns-operator --ignore-not-found'
```

## 5. MetalLB and Fixed VIPs

MetalLB was used to make CoreDNS and Gateway VIPs deterministic.

demo-01:

```yaml
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: demo-01-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.99.210-192.168.99.219
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: demo-01-l2
  namespace: metallb-system
spec:
  interfaces:
    - br-ex
  ipAddressPools:
    - demo-01-pool
```

Per-cluster pool ranges:

```text
demo-01: 192.168.99.210-192.168.99.219
demo-02: 192.168.99.220-192.168.99.239
demo-03: 192.168.99.240-192.168.99.249
```

Patch CoreDNS Service fixed VIPs:

```bash
su - sno  -c 'oc patch svc kuadrant-coredns -n kuadrant-coredns -p '\''{"spec":{"loadBalancerIP":"192.168.99.210"}}'\'''
su - sno2 -c 'oc patch svc kuadrant-coredns -n kuadrant-coredns -p '\''{"spec":{"loadBalancerIP":"192.168.99.230"}}'\'''
su - sno3 -c 'oc patch svc kuadrant-coredns -n kuadrant-coredns -p '\''{"spec":{"loadBalancerIP":"192.168.99.240"}}'\'''
```

Patch baseline Gateway fixed VIPs:

```bash
su - sno  -c 'oc patch svc ingress-gateway-openshift-default -n api-gateway -p '\''{"spec":{"loadBalancerIP":"192.168.99.211"}}'\'''
su - sno2 -c 'oc patch svc ingress-gateway-openshift-default -n api-gateway -p '\''{"spec":{"loadBalancerIP":"192.168.99.221"}}'\'''
su - sno3 -c 'oc patch svc ingress-gateway-openshift-default -n api-gateway -p '\''{"spec":{"loadBalancerIP":"192.168.99.241"}}'\'''
```

For the two-domain test, the extra Gateway VIPs were allocated automatically from the same pools:

```text
Domain A: .212, .220, .242
Domain B: .213, .222, .243
```

## 6. RHCL DNS Provider Secret

The `coredns-credentials` Secret tells RHCL DNS Operator to manage DNS records through the local Kuadrant CoreDNS provider.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: coredns-credentials
  namespace: api-gateway
  labels:
    kuadrant.io/default-provider: "true"
type: kuadrant.io/coredns
stringData:
  ZONES: kuadrant.wzhlab.top
  NAMESERVERS: <local-kuadrant-coredns-cluster-ip>
```

Patch the local Service `clusterIP` into the Secret on each cluster:

```bash
for user in sno sno2 sno3; do
  su - "${user}" -c '
    cluster_ip="$(oc get svc kuadrant-coredns -n kuadrant-coredns -o jsonpath="{.spec.clusterIP}")"
    oc patch secret coredns-credentials -n api-gateway --type merge \
      -p "{\"stringData\":{\"NAMESERVERS\":\"${cluster_ip}\"}}"
  '
done
```

This Secret is not the cross-cluster kubeconfig. It is a provider configuration for CoreDNS.

## 7. RHCL Cross-Cluster Secrets and RBAC

RHCL DNS Operator uses cross-cluster Secrets to read peer DNS state. This is separate from the external test controller.

Representative commands:

```bash
# On demo-01 context, add demo-02 and demo-03 as remote clusters.
kubectl-kuadrant_dns add-cluster-secret \
  --context demo-02 \
  --namespace kuadrant-system \
  --name demo-02 \
  --service-account dns-operator-remote-cluster

kubectl-kuadrant_dns add-cluster-secret \
  --context demo-03 \
  --namespace kuadrant-system \
  --name demo-03 \
  --service-account dns-operator-remote-cluster

# Grant the service account the DNS operator remote-cluster role.
oc adm policy add-cluster-role-to-user dns-operator-remote-cluster-role \
  -z dns-operator-remote-cluster \
  -n kuadrant-system
```

Repeat the same idea for each source cluster so the three clusters form the required peer mesh.

Security note:

```text
kubectl-kuadrant_dns add-cluster-secret creates a Kubernetes Secret containing a kubeconfig.
That kubeconfig contains remote API server information, CA data, and a ServiceAccount credential.
The credential is sensitive and must not be printed in a customer report.
```

## 8. Active-Groups CoreDNS Configuration

The active-groups TXT zone is the hard site membership switch.

For this two-domain validation, each cluster's `kuadrant-coredns` ConfigMap included three active-groups zones:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kuadrant-coredns
  namespace: kuadrant-coredns
data:
  Corefile: |
    kuadrant-active-groups.glb.kuadrant.wzhlab.top:53 {
        errors
        log
        file /etc/coredns/active-groups.db {
            reload 2s
        }
    }
    kuadrant-active-groups.glb-a.kuadrant.wzhlab.top:53 {
        errors
        log
        file /etc/coredns/active-groups-a.db {
            reload 2s
        }
    }
    kuadrant-active-groups.glb-b.kuadrant.wzhlab.top:53 {
        errors
        log
        file /etc/coredns/active-groups-b.db {
            reload 2s
        }
    }
    kuadrant.wzhlab.top:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        log
        metadata
        kuadrant
    }
  active-groups.db: |
    kuadrant-active-groups.glb.kuadrant.wzhlab.top. 10 IN SOA ns1. hostmaster. 1781693568 7200 3600 1209600 10
    kuadrant-active-groups.glb.kuadrant.wzhlab.top. 10 IN NS ns1.
    kuadrant-active-groups.glb.kuadrant.wzhlab.top. 10 IN TXT "version=1;groups=demo-01&&demo-02&&demo-03"
  active-groups-a.db: |
    kuadrant-active-groups.glb-a.kuadrant.wzhlab.top. 10 IN SOA ns1. hostmaster. 1781693568 7200 3600 1209600 10
    kuadrant-active-groups.glb-a.kuadrant.wzhlab.top. 10 IN NS ns1.
    kuadrant-active-groups.glb-a.kuadrant.wzhlab.top. 10 IN TXT "version=1;groups=demo-01&&demo-02&&demo-03"
  active-groups-b.db: |
    kuadrant-active-groups.glb-b.kuadrant.wzhlab.top. 10 IN SOA ns1. hostmaster. 1781693568 7200 3600 1209600 10
    kuadrant-active-groups.glb-b.kuadrant.wzhlab.top. 10 IN NS ns1.
    kuadrant-active-groups.glb-b.kuadrant.wzhlab.top. 10 IN TXT "version=1;groups=demo-01&&demo-02&&demo-03"
```

The Deployment must mount all three files:

```bash
oc patch deployment kuadrant-coredns -n kuadrant-coredns --type json -p '[
  {
    "op":"replace",
    "path":"/spec/template/spec/volumes/0/configMap/items",
    "value":[
      {"key":"Corefile","path":"Corefile"},
      {"key":"active-groups.db","path":"active-groups.db"},
      {"key":"active-groups-a.db","path":"active-groups-a.db"},
      {"key":"active-groups-b.db","path":"active-groups-b.db"}
    ]
  }
]'
```

OpenShift DNS forwarding must know the active-groups zones:

```bash
oc patch dns.operator/default --type json -p '[
  {
    "op": "replace",
    "path": "/spec/servers/0/zones",
    "value": [
      "kuadrant-active-groups.glb.kuadrant.wzhlab.top",
      "kuadrant-active-groups.glb-a.kuadrant.wzhlab.top",
      "kuadrant-active-groups.glb-b.kuadrant.wzhlab.top"
    ]
  }
]'
```

Validation command:

```bash
dig +tcp +short @192.168.99.210 kuadrant-active-groups.glb-a.kuadrant.wzhlab.top TXT
dig +tcp +short @192.168.99.230 kuadrant-active-groups.glb-b.kuadrant.wzhlab.top TXT
dig +tcp +short @192.168.99.240 kuadrant-active-groups.glb-b.kuadrant.wzhlab.top TXT
```

Expected output:

```text
"version=1;groups=demo-01&&demo-02&&demo-03"
```

## 9. Demo Application

The same app was deployed on all clusters. Only the text content differs by cluster.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: connectlink-demo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: echo-content
  namespace: connectlink-demo
data:
  index.html: |
    demo-01 via Connectivity Link GLB
  health: |
    ok
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
  namespace: connectlink-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
        - name: echo
          image: registry.access.redhat.com/ubi9/python-311:latest
          command: ["/bin/bash", "-c"]
          args: ["cd /opt/app-root/src && python -m http.server 8080"]
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: content
              mountPath: /opt/app-root/src
      volumes:
        - name: content
          configMap:
            name: echo-content
---
apiVersion: v1
kind: Service
metadata:
  name: echo
  namespace: connectlink-demo
spec:
  selector:
    app: echo
  ports:
    - name: http
      port: 8080
      targetPort: 8080
```

Per-cluster content:

```text
demo-01 via Connectivity Link GLB
demo-02 via Connectivity Link GLB
demo-03 via Connectivity Link GLB
```

## 10. Two-Domain Gateway / HTTPRoute / DNSPolicy Configuration

Each domain has independent Gateway, HTTPRoute, and DNSPolicy objects.

Domain A:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ingress-gateway-a
  namespace: api-gateway
spec:
  gatewayClassName: openshift-default
  listeners:
    - name: http
      hostname: glb-a.kuadrant.wzhlab.top
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-a
  namespace: connectlink-demo
spec:
  parentRefs:
    - name: ingress-gateway-a
      namespace: api-gateway
  hostnames:
    - glb-a.kuadrant.wzhlab.top
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: echo
          port: 8080
---
apiVersion: kuadrant.io/v1
kind: DNSPolicy
metadata:
  name: ingress-gateway-a-dns
  namespace: api-gateway
spec:
  delegate: true
  healthCheck:
    failureThreshold: 2
    interval: 30s
    path: /health
    port: 80
    protocol: HTTP
  loadBalancing:
    defaultGeo: true
    geo: GEO-NA
    weight: 60
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: ingress-gateway-a
```

Domain B uses the same structure with:

```text
Gateway: ingress-gateway-b
HTTPRoute: echo-b
DNSPolicy: ingress-gateway-b-dns
Hostname: glb-b.kuadrant.wzhlab.top
```

Important namespace rule:

```text
Gateway and DNSPolicy are in api-gateway.
HTTPRoute is in connectlink-demo.
The backend Service is connectlink-demo/echo.
```

Putting the HTTPRoute in `api-gateway` without a `ReferenceGrant` caused an earlier failed attempt. The working pattern is to keep the route in the application namespace.

## 11. Test Method

DNS sample command:

```bash
for ns in 192.168.99.210 192.168.99.230 192.168.99.240; do
  echo "===== nameserver=${ns} ====="
  for i in $(seq 1 120); do
    dig +tcp +short @"${ns}" glb-a.kuadrant.wzhlab.top A | tail -1
  done | sort | uniq -c
done
```

Bad VIP absent check:

```bash
for ns in 192.168.99.210 192.168.99.230 192.168.99.240; do
  echo "===== nameserver=${ns} ====="
  for i in $(seq 1 60); do
    dig +tcp +short @"${ns}" glb-a.kuadrant.wzhlab.top A | tail -1
  done | grep -c '192.168.99.242' || true
done
```

Pass condition:

```text
For a failed endpoint, every nameserver must return bad VIP count = 0.
```

This is stricter than "one query does not show the bad VIP" because weighted DNS is probabilistic.

## 12. Scenario 1: Three Clusters In One Region

All clusters were configured in `GEO-NA`.

Domain A policy:

| Cluster | Group | Geo | VIP | Weight |
|---|---|---|---:|---:|
| demo-01 | demo-01 | GEO-NA | `192.168.99.212` | 60 |
| demo-02 | demo-02 | GEO-NA | `192.168.99.220` | 30 |
| demo-03 | demo-03 | GEO-NA | `192.168.99.242` | 10 |

Domain B policy:

| Cluster | Group | Geo | VIP | Weight |
|---|---|---|---:|---:|
| demo-01 | demo-01 | GEO-NA | `192.168.99.213` | 20 |
| demo-02 | demo-02 | GEO-NA | `192.168.99.222` | 30 |
| demo-03 | demo-03 | GEO-NA | `192.168.99.243` | 50 |

Configuration commands:

```bash
# Domain A: 60 / 30 / 10
su - sno  -c 'oc patch dnspolicy ingress-gateway-a-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":true,"weight":60}}}'\'''
su - sno2 -c 'oc patch dnspolicy ingress-gateway-a-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":false,"weight":30}}}'\'''
su - sno3 -c 'oc patch dnspolicy ingress-gateway-a-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":false,"weight":10}}}'\'''

# Domain B: 20 / 30 / 50
su - sno  -c 'oc patch dnspolicy ingress-gateway-b-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":true,"weight":20}}}'\'''
su - sno2 -c 'oc patch dnspolicy ingress-gateway-b-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":false,"weight":30}}}'\'''
su - sno3 -c 'oc patch dnspolicy ingress-gateway-b-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":false,"weight":50}}}'\'''
```

Healthy DNS result, 120 queries per nameserver:

| Domain | Nameserver | demo-01 | demo-02 | demo-03 |
|---|---:|---:|---:|---:|
| A | `192.168.99.210` | 76 | 35 | 9 |
| A | `192.168.99.230` | 71 | 36 | 13 |
| A | `192.168.99.240` | 81 | 28 | 11 |
| B | `192.168.99.210` | 21 | 38 | 61 |
| B | `192.168.99.230` | 31 | 33 | 56 |
| B | `192.168.99.240` | 18 | 39 | 63 |

This confirms that same-bucket weighting works and that two domains can have different weight distributions.

### 12.1 Scenario 1 Failure: demo-03 App Down

Failure action:

```bash
su - sno3 -c 'oc scale deployment/echo -n connectlink-demo --replicas=0'
```

Failover configuration:

```text
Domain A active-groups: demo-01&&demo-02
Domain B active-groups: demo-01&&demo-02
Domain A demo-03 DNSPolicy weight: 0
Domain B demo-03 DNSPolicy weight: 0
```

Result:

| Domain | Bad VIP | Check |
|---|---:|---|
| A | `192.168.99.242` | `0/60` bad answers on all three nameservers |
| B | `192.168.99.243` | `0/60` bad answers on all three nameservers |

Post-failover DNS samples:

| Domain | Nameserver | Remaining answers |
|---|---:|---|
| A | `192.168.99.210` | `.212`: 79, `.220`: 41 |
| A | `192.168.99.230` | `.212`: 80, `.220`: 40 |
| A | `192.168.99.240` | `.212`: 76, `.220`: 44 |
| B | `192.168.99.210` | `.222`: 77, `.213`: 43 |
| B | `192.168.99.230` | `.222`: 68, `.213`: 52 |
| B | `192.168.99.240` | `.222`: 72, `.213`: 48 |

Restore:

```bash
su - sno3 -c 'oc scale deployment/echo -n connectlink-demo --replicas=1'
```

## 13. Scenario 2: Two Clusters In Region A, One Cluster In Region B

In this test:

```text
demo-01 -> GEO-NA
demo-02 -> GEO-NA
demo-03 -> GEO-EU
```

Domain A:

| Cluster | Geo | VIP | Weight |
|---|---|---:|---:|
| demo-01 | GEO-NA | `192.168.99.212` | 70 |
| demo-02 | GEO-NA | `192.168.99.220` | 20 |
| demo-03 | GEO-EU | `192.168.99.242` | 10 |

Domain B:

| Cluster | Geo | VIP | Weight |
|---|---|---:|---:|
| demo-01 | GEO-NA | `192.168.99.213` | 20 |
| demo-02 | GEO-NA | `192.168.99.222` | 50 |
| demo-03 | GEO-EU | `192.168.99.243` | 30 |

Configuration commands:

```bash
# Domain A: region A 70/20, region B 10
su - sno  -c 'oc patch dnspolicy ingress-gateway-a-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":true,"weight":70}}}'\'''
su - sno2 -c 'oc patch dnspolicy ingress-gateway-a-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":false,"weight":20}}}'\'''
su - sno3 -c 'oc patch dnspolicy ingress-gateway-a-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-EU","defaultGeo":false,"weight":10}}}'\'''

# Domain B: region A 20/50, region B 30
su - sno  -c 'oc patch dnspolicy ingress-gateway-b-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":true,"weight":20}}}'\'''
su - sno2 -c 'oc patch dnspolicy ingress-gateway-b-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-NA","defaultGeo":false,"weight":50}}}'\'''
su - sno3 -c 'oc patch dnspolicy ingress-gateway-b-dns -n api-gateway --type merge -p '\''{"spec":{"loadBalancing":{"geo":"GEO-EU","defaultGeo":false,"weight":30}}}'\'''
```

Healthy DNS result, 120 queries per nameserver:

| Domain | Nameserver | demo-01 | demo-02 | demo-03 |
|---|---:|---:|---:|---:|
| A | `192.168.99.210` | 68 | 13 | 39 |
| A | `192.168.99.230` | 66 | 17 | 37 |
| A | `192.168.99.240` | 70 | 16 | 34 |
| B | `192.168.99.210` | 15 | 56 | 49 |
| B | `192.168.99.230` | 27 | 50 | 43 |
| B | `192.168.99.240` | 22 | 60 | 38 |

Interpretation:

```text
RHCL returned answers from both buckets.
The result is not a single flat global 70/20/10 or 20/50/30 pool.
Same-bucket weights are reliable; cross-bucket behavior must be explained as geo-layered DNS behavior, not Avi-style global pool weighting.
```

### 13.1 Scenario 2 Failure: Region A Member demo-02 Down

Failure action:

```bash
su - sno2 -c 'oc scale deployment/echo -n connectlink-demo --replicas=0'
```

Failover configuration:

```text
Domain A active-groups: demo-01&&demo-03
Domain B active-groups: demo-01&&demo-03
Domain A demo-02 DNSPolicy weight: 0
Domain B demo-02 DNSPolicy weight: 0
```

Result:

| Domain | Bad VIP | Check |
|---|---:|---|
| A | `192.168.99.220` | `0/60` bad answers on all three nameservers |
| B | `192.168.99.222` | `0/60` bad answers on all three nameservers |

Post-failover DNS samples:

| Domain | Nameserver | Remaining answers |
|---|---:|---|
| A | `192.168.99.210` | `.212`: 79, `.242`: 41 |
| A | `192.168.99.230` | `.212`: 80, `.242`: 40 |
| A | `192.168.99.240` | `.212`: 76, `.242`: 44 |
| B | `192.168.99.210` | `.213`: 74, `.243`: 46 |
| B | `192.168.99.230` | `.213`: 82, `.243`: 38 |
| B | `192.168.99.240` | `.213`: 91, `.243`: 29 |

Restore:

```bash
su - sno2 -c 'oc scale deployment/echo -n connectlink-demo --replicas=1'
```

### 13.2 Scenario 2 Failure: Region B Member demo-03 Down

Failure action:

```bash
su - sno3 -c 'oc scale deployment/echo -n connectlink-demo --replicas=0'
```

Failover configuration:

```text
Domain A active-groups: demo-01&&demo-02
Domain B active-groups: demo-01&&demo-02
Domain A demo-03 DNSPolicy weight: 0
Domain B demo-03 DNSPolicy weight: 0
```

Result:

| Domain | Bad VIP | Check |
|---|---:|---|
| A | `192.168.99.242` | `0/60` bad answers on all three nameservers on first check |
| B | `192.168.99.243` | First check saw `9/60` on `192.168.99.240`; second check was `0/60` on all three nameservers |

Post-failover DNS samples:

| Domain | Nameserver | Remaining answers |
|---|---:|---|
| A | `192.168.99.210` | `.212`: 94, `.220`: 26 |
| A | `192.168.99.230` | `.212`: 83, `.220`: 37 |
| A | `192.168.99.240` | `.212`: 94, `.220`: 26 |
| B | `192.168.99.210` | `.222`: 83, `.213`: 37 |
| B | `192.168.99.230` | `.222`: 89, `.213`: 31 |
| B | `192.168.99.240` | `.222`: 88, `.213`: 32 |

Restore:

```bash
su - sno3 -c 'oc scale deployment/echo -n connectlink-demo --replicas=1'
```

## 14. Why `DNSPolicy.weight=0` Alone Is Not Enough

One failed attempt intentionally tested weight-only failover.

Observed state:

```text
DNSPolicy spec.loadBalancing.weight: 0
DNSPolicy condition: HealthChecksFailed
DNSHealthCheckProbe: false
dig glb-b.kuadrant.wzhlab.top: still returned 192.168.99.243
```

Conclusion:

```text
For production failover, do not treat weight=0 as the only exclusion mechanism.
Use active-groups, or an equivalent pool membership mechanism, as the hard include/exclude switch.
Still patch weight=0 for intent, observability, and alignment with policy.
Always verify the final DNS answer.
```

## 15. External Controller Recommendation

The PoC used scripts/test logic to patch per-domain active-groups and DNSPolicy. A production controller should implement the same logic continuously.

Recommended controller behavior:

```text
Input:
  hostname
  group
  helperUser or kubeconfig reference
  baseWeight
  geo
  defaultGeo
  health probe owner
  active-groups FQDN

Loop:
  read DNSHealthCheckProbe per hostname/site
  compute healthy groups per hostname
  patch that hostname active-groups TXT on all authoritative CoreDNS instances
  patch DNSPolicy weight to baseWeight when healthy
  patch DNSPolicy weight to 0 when unhealthy
  verify final DNS answer until bad VIP is absent
```

Example CRD shape used in the single-domain controller test:

```yaml
apiVersion: rhcl-lab.wzhlab.top/v1alpha1
kind: GlobalTrafficPolicy
metadata:
  name: glb-kuadrant
  namespace: rhcl-glb-controller
spec:
  activeGroupsFQDN: kuadrant-active-groups.glb.kuadrant.wzhlab.top.
  ttl: 10
  strategies:
    - active-groups
    - dnspolicy-weight
  sites:
    - group: demo-01
      helperUser: sno
      baseWeight: 60
      geo: GEO-NA
      defaultGeo: true
      corednsNamespace: kuadrant-coredns
      corednsConfigMap: kuadrant-coredns
      dnsPolicyNamespace: api-gateway
      dnsPolicyName: ingress-gateway-dns
      probeNamespace: api-gateway
      probeOwner: ingress-gateway-http
    - group: demo-02
      helperUser: sno2
      baseWeight: 30
      geo: GEO-NA
      defaultGeo: false
      corednsNamespace: kuadrant-coredns
      corednsConfigMap: kuadrant-coredns
      dnsPolicyNamespace: api-gateway
      dnsPolicyName: ingress-gateway-dns
      probeNamespace: api-gateway
      probeOwner: ingress-gateway-http
    - group: demo-03
      helperUser: sno3
      baseWeight: 10
      geo: GEO-NA
      defaultGeo: false
      corednsNamespace: kuadrant-coredns
      corednsConfigMap: kuadrant-coredns
      dnsPolicyNamespace: api-gateway
      dnsPolicyName: ingress-gateway-dns
      probeNamespace: api-gateway
      probeOwner: ingress-gateway-http
```

For two domains, the controller should make the active-groups state hostname-scoped:

```text
glb-a.kuadrant.wzhlab.top -> kuadrant-active-groups.glb-a.kuadrant.wzhlab.top
glb-b.kuadrant.wzhlab.top -> kuadrant-active-groups.glb-b.kuadrant.wzhlab.top
```

## 16. Avi Replacement Analysis

The customer requirement was:

```text
We are looking for an alternative to Avi ALB that performs multi-geo, multi-cluster load balancing.
```

### 16.1 What RHCL can replace based on this E2E

| Requirement | Result | Notes |
|---|---|---|
| Publish one app hostname from multiple OpenShift clusters | Validated | Baseline single-domain and two-domain tests both worked. |
| Publish multiple hostnames with independent policy | Validated | `glb-a` and `glb-b` used different weights and different Gateway VIPs. |
| Weighted traffic distribution among healthy clusters | Validated inside same bucket | Scenario 1 proved per-domain same-bucket weights. |
| Health-based cluster removal | Validated | Requires active-groups membership update and convergence wait. |
| Recover failed cluster into pool | Validated operationally | The tests restored app replicas and active-groups to full membership. |
| Use OpenShift-native Gateway API/RHCL objects | Validated | Gateway, HTTPRoute, DNSPolicy, DNSRecord, DNSHealthCheckProbe all participated. |

### 16.2 What RHCL partially replaces

| Requirement | Status | Gap |
|---|---|---|
| Multi-region DNS survival | Partially validated | Failed region member can be removed, but empty-bucket behavior and fallback policy must be designed. |
| Global weighted pool across regions | Not equivalent | RHCL geo buckets are not one flat global weight pool. |
| Centralized GSLB policy | PoC controller only | Needs production controller packaging, HA, RBAC, observability, and reconciliation semantics. |
| SLA-grade failover | Needs measurement | Health check interval plus CoreDNS/RHCL convergence must be part of the failover SLA. |

### 16.3 What RHCL does not replace in this PoC

| Avi GSLB feature | RHCL PoC status |
|---|---|
| Closest data center selection based on client location | Not validated as native capability. |
| Best-performing data center based on latency/performance | Not implemented. |
| EDNS Client Subnet based answer selection | Not supported in this PoC. |
| Avi GSLB leader/site federation | Not implemented. |
| Full global service object model with pool/member health, algorithm, persistence, and site federation | Requires external controller or upstream product capability. |

### 16.4 Recommended customer positioning

Use this RHCL design when the customer needs:

```text
OpenShift-native DNS-based multi-cluster publication
weighted distribution among healthy clusters
health-based DNS failover
multiple hostnames with independent routing policy
```

Do not position this PoC as a full Avi GSLB replacement when the customer requires:

```text
closest-site routing
best-performing-site routing
native geo/ECS decisioning
Avi-like GSLB site federation
central GUI/API for global application service lifecycle
```

The credible migration strategy is:

1. Start with RHCL for OpenShift-native Gateway + DNSPolicy + health-based failover.
2. Add a production external controller for hostname-scoped active-groups and DNSPolicy reconciliation.
3. If the customer requires location or performance routing, integrate with upstream DNS/GSLB or extend the controller with geo/ECS/latency data sources.
4. Treat Avi migration as capability-by-capability replacement, not as a one-shot product swap.

## 17. Final Conclusion

This validation reached the following technical conclusion:

```text
RHCL can support a practical DNS-based GLB pattern for three OpenShift clusters and two independent domains.
Same-region weighted distribution works.
Application failure can be removed from DNS answers.
The robust failover mechanism is per-domain active-groups plus DNSPolicy intent.
```

This validation did not prove full Avi GSLB equivalence:

```text
No native closest-site algorithm was validated.
No native best-performing-site algorithm was validated.
No native ECS/client-location answer selection was validated.
No Avi-style GSLB site federation was implemented.
```

Therefore, RHCL is a strong candidate for OpenShift-native multi-cluster DNS failover and weighted DNS distribution, but a complete Avi replacement requires additional geo/performance routing design and a production-grade controller/control-plane layer.
