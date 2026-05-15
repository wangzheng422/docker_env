# Customer — OpenShift Serverless Adoption Guide (Enhanced)

## Executive Summary

Customer 目前在 AWS 上运行大量 Lambda 函数，每个云厂商都需要单独的 CI/CD 流程。这带来了巨大的运维开销和厂商锁定风险。通过采用 **Red Hat OpenShift Serverless**（基于 Knative），Customer 可以将所有 serverless 工作负载统一到一个平台，使用**一套 CI/CD 流程**，可移植地部署到 AWS（ROSA）、Azure（ARO）、阿里云和 GCP —— 同时利用 **scale-to-zero**、**Spot 实例优先调度**和 **Karpenter 智能节点管理**来最大化成本节约。

### 实测验证摘要

本方案已在 ROSA HCP 4.20.22 集群上完成端到端验证，与 AWS Lambda 进行了直接对比测试：

| 指标 | AWS Lambda | OpenShift Serverless (Knative) |
|------|-----------|-------------------------------|
| **冷启动延迟（有节点）** | ~292ms | ~1.67s |
| **冷启动延迟（从零节点）** | N/A（AWS 托管） | ~205-255s（含 EC2 启动 + 节点加入） |
| **热请求延迟** | ~44-55ms | ~28-37ms |
| **Scale-to-Zero** | 自动（~15min） | 自动（~90s，可配置） |
| **节点 Scale-to-Zero** | N/A | 自动（~15min） |
| **部署复杂度** | 11 个 CLI 命令，3 个 AWS 服务 | 1 个 `oc apply` 命令 |
| **多云支持** | 仅 AWS | ROSA / ARO / OCP（任意云） |
| **CI/CD 管道** | 每个云单独维护 | 一套管道适配所有集群 |

此外，针对客户特别关注的 **工作流编排** 能力，我们还对比了 **SonataFlow (Serverless Logic)** 和 **AWS Step Functions**：

| 指标 | AWS Step Functions | SonataFlow on ROSA |
|------|-------------------|-------------------|
| **工作流执行延迟** | ~2ms (Express) | ~46ms (热请求) |
| **首次请求** | ~962ms (含 CLI 开销) | ~220ms |
| **工作流规范** | ASL (AWS 专有) | CNCF Serverless Workflow (开放标准) |
| **多云可移植** | 仅 AWS | 任何 OCP 集群 |
| **K8s 原生** | 否 | CRD + Operator |

> 详细测试步骤和完整命令输出见 `steps-01.md`

---

## 1. 架构概览

### 1.1 当前状态 vs. 目标状态

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          当前状态                                           │
│                                                                             │
│   ┌──────────┐    ┌──────────────┐                                          │
│   │ AWS      │    │ CI/CD for    │   ← 每个云单独的 CI/CD 管道               │
│   │ Lambda   │◄───│ AWS Lambda   │   ← AWS 专属 SDK, 触发器, IAM            │
│   │ (多个)   │    │ (SAM/CDK)    │                                          │
│   └──────────┘    └──────────────┘                                          │
│                                                                             │
│   ┌──────────┐    ┌──────────────┐                                          │
│   │ Azure    │    │ CI/CD for    │   ← 另一套单独的管道                      │
│   │ Functions│◄───│ Azure Func   │   ← Azure 专属 bindings, triggers        │
│   │ (未来)   │    │ (func CLI)   │                                          │
│   └──────────┘    └──────────────┘                                          │
│                                                                             │
│   问题: N 个云 × M 个函数 = N×M 条 CI/CD 管道                              │
└─────────────────────────────────────────────────────────────────────────────┘

                              ▼  迁移  ▼

┌─────────────────────────────────────────────────────────────────────────────┐
│                          目标状态                                           │
│                                                                             │
│              ┌──────────────────────────────┐                                │
│              │  一套统一的 CI/CD Pipeline     │                                │
│              │  (Tekton / OpenShift Pipelines │                               │
│              │   + OpenShift GitOps/ArgoCD)   │                                │
│              └──────────┬───────────────────┘                                │
│                         │                                                    │
│              ┌──────────▼───────────────────┐                                │
│              │  容器镜像 (OCI)               │                                │
│              │  + Knative Service YAML       │                                │
│              └──────────┬───────────────────┘                                │
│                         │                                                    │
│         ┌───────────────┼───────────────────────┐                            │
│         ▼               ▼                       ▼                            │
│   ┌──────────┐    ┌──────────┐           ┌──────────┐                        │
│   │  ROSA    │    │  ARO     │           │  OCP on  │                        │
│   │  (AWS)   │    │  (Azure) │           │  Ali/GCP │                        │
│   │ Knative  │    │ Knative  │           │ Knative  │                        │
│   │ Serving  │    │ Serving  │           │ Serving  │                        │
│   └──────────┘    └──────────┘           └──────────┘                        │
│                                                                             │
│   结果: 1 条管道 × M 个函数 = M 条 CI/CD 管道（云无关）                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 详细组件架构（含 Spot 优先 + Karpenter 路线图）

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    OpenShift 集群 (ROSA HCP)                                     │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                  托管控制面 (Hosted Control Plane)                          │ │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │ │
│  │   │ API Server   │  │ etcd         │  │ Controllers  │  │ Karpenter*   │  │ │
│  │   └──────────────┘  └──────────────┘  └──────────────┘  │ (托管,未来)  │  │ │
│  │                                                          └──────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │              Serverless 基础组件 (运行在 Worker / Infra 节点)              │ │
│  │   ┌─────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  │ │
│  │   │ Knative Serving │  │ Knative Eventing     │  │ Kourier Ingress      │  │ │
│  │   │ Controller      │  │ Controller           │  │ Gateway              │  │ │
│  │   │ Activator       │  │ PingSource Adapter   │  │ (自动 TLS 路由)      │  │ │
│  │   │ Autoscaler      │  │ IMC Controller       │  │                      │  │ │
│  │   └─────────────────┘  └──────────────────────┘  └──────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │         专用 Serverless 机器池 — Spot 优先 + On-Demand 兜底               │ │
│  │                                                                             │ │
│  │   Node Taint: serverless=true:NoSchedule                                    │ │
│  │   Node Label: node-role.kubernetes.io/serverless=""                          │ │
│  │                                                                             │ │
│  │   ┌─────────────────────────────────┐  ┌──────────────────────────────┐     │ │
│  │   │  serverless-spot (优先)         │  │  serverless-od (兜底)         │     │ │
│  │   │  Instance: m6a.xlarge           │  │  Instance: m6a.xlarge         │     │ │
│  │   │  Autoscaling: 0-5              │  │  Autoscaling: 0-3            │     │ │
│  │   │  Spot 实例 (~55% 节省)          │  │  On-Demand 实例              │     │ │
│  │   │                                 │  │  (Spot 不可用时的后备)       │     │ │
│  │   │  ┌─────────┐ ┌─────────┐       │  │  ┌─────────┐                │     │ │
│  │   │  │ Knative │ │ Knative │       │  │  │ Knative │                │     │ │
│  │   │  │Service A│ │Service B│       │  │  │Service C│                │     │ │
│  │   │  │(pods)   │ │(pods)   │       │  │  │(pods)   │                │     │ │
│  │   │  └─────────┘ └─────────┘       │  │  └─────────┘                │     │ │
│  │   └─────────────────────────────────┘  └──────────────────────────────┘     │ │
│  │                                                                             │ │
│  │   所有 pod 缩零 → 集群自动缩容移除节点 → 计算成本 $0                       │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘

* Karpenter 目前为 ROSA HCP 上的 Technology Preview，预计下一个 OCP 小版本 GA
```

---

## 2. 实施步骤

### Phase 1: 安装 OpenShift Serverless（第 1-2 周）

#### Step 1.1: 安装 OpenShift Serverless Operator

```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-serverless
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: serverless-operators
  namespace: openshift-serverless
spec: {}
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serverless-operator
  namespace: openshift-serverless
spec:
  channel: stable
  installPlanApproval: Automatic
  name: serverless-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# 验证 Operator 安装完成（约 30-60 秒）
oc get csv -n openshift-serverless
# 预期输出: serverless-operator.v1.37.1 ... Succeeded
```

> **实测结果**: Serverless Operator v1.37.1 在约 30 秒内安装成功。

**官方文档**: [安装 OpenShift Serverless](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/installing_openshift_serverless/install-serverless-operator)

#### Step 1.2: 安装 Knative Serving

> **重要**: 必须在 `features` 中启用 `kubernetes.podspec-nodeselector`、`kubernetes.podspec-tolerations` 和 `kubernetes.podspec-affinity`。这些是将 Knative Service 调度到专用 Serverless 节点池的**前提条件** —— 默认不启用，不开启的话 Knative Service YAML 中无法使用 `nodeSelector`、`tolerations` 和 `affinity` 字段。

```bash
cat <<EOF | oc apply -f -
apiVersion: operator.knative.dev/v1beta1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  ingress:
    kourier:
      enabled: true
  config:
    features:
      kubernetes.podspec-nodeselector: "enabled"
      kubernetes.podspec-tolerations: "enabled"
      kubernetes.podspec-affinity: "enabled"
    network:
      ingress-class: kourier.ingress.networking.knative.dev
    autoscaler:
      enable-scale-to-zero: "true"
      scale-to-zero-grace-period: "30s"
      stable-window: "60s"
    defaults:
      revision-timeout-seconds: "300"
EOF

oc wait --for=condition=Ready knativeserving/knative-serving \
  -n knative-serving --timeout=300s
```

> **实测结果**: KnativeServing (Knative 1.17) 在约 50 秒内就绪。

**官方文档**: [Knative Serving 配置](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/serving/knative-serving-configuration)

#### Step 1.3: 安装 Knative Eventing

```bash
cat <<EOF | oc apply -f -
apiVersion: operator.knative.dev/v1beta1
kind: KnativeEventing
metadata:
  name: knative-eventing
  namespace: knative-eventing
spec:
  config:
    default-ch-webhook:
      default-ch-config: |
        clusterDefault:
          apiVersion: messaging.knative.dev/v1
          kind: InMemoryChannel
EOF

oc wait --for=condition=Ready knativeeventing/knative-eventing \
  -n knative-eventing --timeout=300s
```

> **实测结果**: KnativeEventing (1.17) 在约 90 秒内就绪。

**官方文档**: [Knative Eventing 配置](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/eventing/knative-eventing-configuration)

---

### Phase 2: Spot 优先 + On-Demand 兜底的节点池策略（第 2-3 周）

> **客户需求**: ROSA 的 machinepool 管理能力有限，希望使用 Karpenter 进行更灵活的节点管理。在 Karpenter GA 之前，使用双机器池策略实现 Spot 优先调度。

#### Step 2.1: 当前方案 — 双机器池 + NodeAffinity

ROSA HCP 当前使用 `rosa create machinepool` 管理节点池。通过创建**两个独立的机器池**（Spot + On-Demand），配合 Knative Service 的 `nodeAffinity` 实现 Spot 优先调度：

```bash
# 1. 创建 Spot 实例机器池（优先使用）
rosa create machinepool \
  --cluster=<cluster-name> \
  --name=serverless-spot \
  --instance-type=m6a.xlarge \
  --min-replicas=0 \
  --max-replicas=5 \
  --enable-autoscaling \
  --labels="node-role.kubernetes.io/serverless=,capacity-type=spot" \
  --taints="serverless=true:NoSchedule" \
  --use-spot-instances \
  --spot-max-price=on-demand \
  --autorepair \
  -y

# 2. 创建 On-Demand 实例机器池（Spot 不可用时的兜底）
rosa create machinepool \
  --cluster=<cluster-name> \
  --name=serverless-od \
  --instance-type=m6a.xlarge \
  --min-replicas=0 \
  --max-replicas=3 \
  --enable-autoscaling \
  --labels="node-role.kubernetes.io/serverless=,capacity-type=on-demand" \
  --taints="serverless=true:NoSchedule" \
  --autorepair \
  -y

# 验证
rosa list machinepools --cluster=<cluster-name>
```

**核心设计:**

| 机器池 | 角色 | Autoscaling | Spot | 成本 (m6a.xlarge, us-east-2) |
|--------|------|-------------|------|------|
| `serverless-spot` | 优先 | 0-5 | 是 | ~$0.077/hr |
| `serverless-od` | 兜底 | 0-3 | 否 | ~$0.173/hr |

> **实测 Spot 价格**: m6a.xlarge 在 us-east-2a 的 Spot 价格为 $0.077/hr，On-Demand 为 $0.173/hr，**Spot 节省约 55%**。

#### Step 2.2: Knative Service 配置 — Spot 优先调度

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: my-function
  namespace: serverless-demo
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/min-scale: "0"
        autoscaling.knative.dev/max-scale: "10"
    spec:
      tolerations:
        - key: "serverless"
          operator: "Equal"
          value: "true"
          effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/serverless: ""
      affinity:
        nodeAffinity:
          # 优先调度到 Spot 节点（权重 100）
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              preference:
                matchExpressions:
                  - key: capacity-type
                    operator: In
                    values:
                      - spot
      containers:
        - image: <registry>/<project>/my-function:latest
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
```

**调度优先级逻辑:**

```
请求到达
    │
    ▼
┌──────────────┐     有 Spot 节点？     ┌──────────────────┐
│ Knative      │────── Yes ────────────▶│ 调度到 Spot 节点  │
│ Activator    │                        │ (权重 100)        │
└──────┬───────┘                        └──────────────────┘
       │
       │ No（Spot 不可用）
       ▼
┌──────────────────┐
│ 调度到 On-Demand  │ ← nodeSelector 匹配 serverless 角色
│ 节点 (兜底)      │    无需 Spot 标签也可调度
└──────────────────┘
```

> **实测验证**: 当 Spot 和 On-Demand 节点都可用时，pod 优先调度到 Spot 节点。当仅有 On-Demand 节点时，pod 正确回退到 On-Demand 节点。

#### Step 2.3: 成本节约流程

```
  无流量                                               流量到达
  ─────────                                            ──────────

  ┌──────────┐     ┌──────────────┐     ┌──────────────┐
  │ 请求     │     │ Knative      │     │ 机器池       │
  │ 速率 = 0 │────▶│ Scale-to-Zero│────▶│ 节点 = 0     │──── 成本 = $0
  │          │     │ Pods = 0     │     │ (自动缩容)   │
  └──────────┘     └──────────────┘     └──────────────┘

  ┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
  │ 请求     │     │ Activator    │     │ 集群         │     │ Knative  │
  │ 到达     │────▶│ 缓冲请求     │────▶│ 自动扩容     │────▶│ Pod      │
  │          │     │              │     │ 添加节点     │     │ 启动     │
  └──────────┘     └──────────────┘     └──────────────┘     └──────────┘
                                                                │
                                                                ▼
                                                         ┌──────────────┐
                                                         │ 请求被处理   │
                                                         └──────────────┘

  时间线（从零节点冷启动 — 实测）:
  ├── 请求到达 ──┤── EC2 启动 ~150s ──┤── 节点加入 ~30s ──┤── Pod 就绪 ~25s ──┤
  │              │ AWS 创建 EC2       │ RHCOS 引导        │ 镜像拉取 +       │
  │              │ 实例               │ 注册到集群        │ 容器启动          │
  │              │                    │                   │ 总计 ~205s       │

  时间线（缩零到零节点 — 实测）:
  ├── 流量停止 ──┤── 15-30s 宽限期 ──┤── 60s 稳定窗口 ──┤── ~15min 空闲 ──┤
  │              │ pods 仍在运行     │ pods 终止         │ 节点被移除      │
  │              │ (可配置)          │ (scale-to-zero)   │ (集群自动缩容)  │
```

---

### Phase 2b: Karpenter 路线图 — 下一代节点管理（预计 Q3 2026 GA）

> **客户需求 1**: ROSA 的 machinepool 能力薄弱，希望使用 Karpenter 管理节点<br>
> **客户需求 2**: Spot 优先，On-Demand 兜底<br>
> **客户需求 3**: On-Demand 节点运行中，Spot 空余后自动替换

#### 2b.1 当前状态

| 维度 | 当前（Machine Pool） | 未来（Red Hat Build of Karpenter） |
|------|---------------------|----------------------------------|
| **状态** | GA (ROSA HCP 4.20+) | Technology Preview（预计下一个 OCP 小版本 GA） |
| **节点管理** | `rosa create machinepool` CLI | Kubernetes CRD (`NodePool` + `EC2NodeClass`) |
| **Spot 优先** | 需双机器池 + NodeAffinity | **原生内建**: spot → on-demand 自动优先级 |
| **节点整合** | 无（空闲节点需等待自动缩容超时） | **WhenEmptyOrUnderutilized** 持续优化 |
| **OD→Spot 替换** | 不支持 | **原生支持**: 整合循环自动检测并替换 |
| **实例类型选择** | 手动指定单一类型 | 自动从 400+ 类型中选最优 |
| **控制器位置** | N/A（AWS ASG 管理） | 托管在 HCP 中，**零额外 Pod** |
| **与 CA 共存** | N/A | 支持混合使用 |

#### 2b.2 Karpenter 架构在 ROSA HCP 上的实现

```
┌─────────────────────────────────────────────────────────────────┐
│                 ROSA HCP 托管控制面                               │
│                                                                 │
│   ┌──────────────────┐   ┌──────────────────┐                   │
│   │ Karpenter        │   │ API Server       │                   │
│   │ Controller       │──▶│ Watch Pods       │                   │
│   │ (托管, 无需管理)  │   │ & NodePool CRDs  │                   │
│   └────────┬─────────┘   └──────────────────┘                   │
│            │                                                     │
│            │ 1. 检测 unschedulable pods                          │
│            │ 2. 评估 NodePool 约束                               │
│            │ 3. 调用 EC2 CreateFleet API                        │
│            ▼                                                     │
│   ┌──────────────────────────────────────────────────┐          │
│   │ EC2 CreateFleet API                               │          │
│   │ 优先级: Reserved → Spot → On-Demand              │          │
│   │ 策略: price-capacity-optimized                    │          │
│   │ 候选: 400+ 实例类型 × 多 AZ                      │          │
│   └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Worker 节点                                │
│                                                                 │
│   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐    │
│   │ Spot m6a.xl   │   │ Spot c6a.xl   │   │ OD m6a.xl     │    │
│   │ (最优选择)    │   │ (备选)        │   │ (兜底)        │    │
│   │ Knative Pods  │   │ Knative Pods  │   │ Knative Pods  │    │
│   └───────────────┘   └───────────────┘   └───────────────┘    │
│                                                                 │
│   整合循环:                                                      │
│   - 空闲节点 → 删除                                             │
│   - On-Demand 节点 + Spot 空余 → 替换为 Spot                   │
│   - 利用率低 → 合并 Pod + 缩减节点                              │
└─────────────────────────────────────────────────────────────────┘
```

#### 2b.3 Karpenter NodePool 配置示例（GA 后可用）

```yaml
# Karpenter NodePool — Spot 优先 + On-Demand 兜底
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: serverless-workloads
spec:
  template:
    metadata:
      labels:
        node-role.kubernetes.io/serverless: ""
    spec:
      requirements:
        # Spot 优先，On-Demand 兜底（Karpenter 内建优先级: Reserved → Spot → On-Demand）
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        # 允许多种实例类型（Karpenter 自动选最优）
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gte
          values: ["5"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
      taints:
        - key: serverless
          value: "true"
          effect: NoSchedule
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: serverless-class
      expireAfter: 720h
  # 节点整合策略
  disruption:
    # 空闲或利用率低时自动整合（实现 OD→Spot 自动替换）
    consolidationPolicy: WhenEmptyOrUnderutilized
    # 整合前等待时间（避免频繁波动）
    consolidateAfter: 1m
    # 限制同时整合的节点数（保护可用性）
    budgets:
      - nodes: "10%"
      # 工作日 9-18 点不做整合（避免影响业务）
      - schedule: "0 9 * * mon-fri"
        duration: 9h
        nodes: "0"
  # 资源限制（防止失控扩容）
  limits:
    cpu: 100
    memory: 200Gi
```

#### 2b.4 Karpenter 如何实现客户三大需求

**需求 1: Spot 优先，On-Demand 兜底**

Karpenter 内建优先级 `Reserved → Spot → On-Demand`。当 `karpenter.sh/capacity-type` 同时包含 `spot` 和 `on-demand` 时，Karpenter 自动优先选择 Spot。若 Spot 无容量（缓存 3 分钟），毫秒级切换到 On-Demand。

**需求 2: On-Demand 运行中 → Spot 恢复后自动替换**

`consolidationPolicy: WhenEmptyOrUnderutilized` 启用后，Karpenter 持续监控节点成本：
1. 检测到 On-Demand 节点上的 Pod 可以迁移到更便宜的 Spot 节点
2. 创建新的 Spot 节点 → 等待 Ready → 驱逐 On-Demand 节点上的 Pod（遵守 PDB）→ 删除空的 On-Demand 节点
3. 零人工干预，budgets 控制替换速率

**需求 3: 从零节点冷启动加速**

Karpenter 直接调用 EC2 CreateFleet API，跳过 Cluster Autoscaler → ASG 中间层，预计冷启动时间从 ~205s 缩短至 ~120-150s（30-50% 改善）。

#### 2b.5 从 Machine Pool 迁移到 Karpenter 的路径

```
阶段 1（当前 — GA 前）:
  serverless-spot (Machine Pool, Spot, 0-5)
  serverless-od   (Machine Pool, OD,   0-3)
  + Knative Service NodeAffinity (preferredSpot)

阶段 2（Karpenter GA 后 — 混合期）:
  serverless-od   (Machine Pool, OD 兜底, 0-1)   ← 保留少量 OD 兜底
  Karpenter NodePool (Spot+OD, consolidation)    ← 主力

阶段 3（全面 Karpenter）:
  Karpenter NodePool (serverless-workloads)
  Spot 优先 + OD 兜底 + WhenEmptyOrUnderutilized
  删除旧 Machine Pool
```

> **参考文档**:
> - [Red Hat Build of Karpenter on ROSA](https://aws.amazon.com/blogs/ibm-redhat/cut-costs-scale-smarter-with-rosa-karpenter-automates-compute-provisioning/)
> - [Karpenter NodePool 文档](https://karpenter.sh/docs/concepts/nodepools/)
> - [AWS Karpenter Best Practices](https://docs.aws.amazon.com/eks/latest/best-practices/karpenter.html)
> - [Spot-to-Spot Consolidation](https://aws.amazon.com/blogs/compute/applying-spot-to-spot-consolidation-best-practices-with-karpenter/)

---

### Phase 3: Lambda 到 Knative 迁移（第 3-5 周）

> 内容与 `solution.md` Phase 3 相同（Lambda 概念映射、函数转换、kn func 开发体验等），此处不再重复。

---

### Phase 4: 统一 CI/CD 管道（第 4-6 周）

> 内容与 `solution.md` Phase 4 相同（Tekton Pipeline、GitOps 仓库结构等），此处不再重复。

---

### Phase 5: 事件源集成（第 5-7 周）

> 内容与 `solution.md` Phase 5 相同（PingSource、KafkaSource、Direct Sink 模式等），此处不再重复。

---

### Phase 6: 成本优化配置（第 6-7 周）

#### Step 6.1: 自动扩缩参数调优

| 参数 | 推荐值 | 用途 |
|------|--------|------|
| `autoscaling.knative.dev/min-scale` | `"0"` | 空闲时缩零（最大节省） |
| `autoscaling.knative.dev/max-scale` | `"50"` per function | 防止失控扩容 |
| `autoscaling.knative.dev/target` | `"50"` | 每 pod 并发请求数 |
| `autoscaling.knative.dev/scale-down-delay` | `"15s"` | 缩容前等待时间 |
| `scale-to-zero-grace-period` | `"30s"` (全局) | 终止最后一个 pod 前的宽限期 |
| `stable-window` | `"60s"` (全局) | 稳定自动扩缩决策的时间窗口 |

#### Step 6.2: 成本对比模型

| 因素 | AWS Lambda | Knative on ROSA (Spot) |
|------|-----------|----------------------|
| 调用成本 | $0.20/百万请求 | $0（包含在计算中） |
| 计算 (128MB, 1s) | $0.0000021/请求 | Scale-to-zero = 空闲时 $0 |
| 节点成本 (Spot) | N/A | m6a.xlarge spot ~$0.077/hr |
| 节点成本 (On-Demand) | N/A | m6a.xlarge OD ~$0.173/hr |
| 节点空闲成本 | N/A | $0（自动缩容移除节点） |
| 多云 CI/CD | 每云单独管道 | 一条管道适配所有 |

#### Step 6.3: Spot 实例中断处理

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-function-pdb
  namespace: serverless-demo
spec:
  minAvailable: 1
  selector:
    matchLabels:
      serving.knative.dev/service: order-processor
```

对于不能容忍冷启动的关键函数，设置 `minScale: "1"` 并使用 On-Demand 节点。

---

### Phase 7: Serverless Logic — 工作流编排（第 7-9 周）

> 内容与 `solution.md` Phase 8 相同（SonataFlow vs AWS Step Functions），此处不再重复。

---

### Phase 8: 运维手册（第 9-10 周）

> 内容与 `solution.md` Phase 9 相同（监控指标、常用运维操作、故障排查），此处不再重复。

---

## 3. 从零节点冷启动 Use Case — 完整时序分析

> **客户需求**: 从零节点开始，创建 EC2，加载 serverless workload，测量请求延迟。同样，测量销毁延迟。

### 3.1 Scale-Up 时序（从零到处理第一个请求）

```
T=0s     请求到达 Knative Activator
         ├── Activator 检测到 desired replicas = 0
         ├── 创建 pod（Pending 状态）
         └── 集群自动缩容器检测到 FailedScheduling

T~20s    集群自动缩容器决定扩容
         ├── 向 ROSA HCP 控制面发起节点请求
         └── AWS EC2 CreateFleet API 调用

T~30s    EC2 实例开始启动
         ├── RHCOS AMI 引导
         ├── kubelet 启动
         └── CSI/CNI 插件初始化

T~150s   节点注册到集群（Status: Ready）
         ├── kube-apiserver 接受节点
         ├── DaemonSet pods 部署（CNI, CSR, monitoring 等）
         └── 节点标记为可调度

T~180s   Pod 被调度到新节点
         ├── 容器镜像拉取
         ├── 容器启动
         └── Readiness probe 通过

T~205s   第一个请求成功响应（HTTP 200）

T~205s+  后续热请求: ~30-37ms
```

### 3.2 Scale-Down 时序（从有节点到零节点）

```
T=0s       最后一个请求处理完成

T+15-30s   Knative scale-down-delay 到期

T+~90s     Pod 被缩零
           ├── scale-to-zero-grace-period (30s)
           ├── stable-window (60s)
           └── 最后一个 pod 终止

T+~6min    第一个空闲节点被移除

T+~15min   所有空闲节点被移除，EC2 终止，成本 = $0

           Karpenter 预计可将节点移除时间缩短至 1-5 分钟
           (consolidateAfter: 1m, consolidationPolicy: WhenEmptyOrUnderutilized)
```

### 3.3 实测数据汇总

| 指标 | On-Demand 池 | Spot 池 |
|------|-------------|---------|
| **从零节点到第一个响应** | ~205s | ~255s |
| **EC2 实例启动 → 节点 Ready** | ~150s | ~200s |
| **Pod 调度 → 容器就绪** | ~55s | ~55s |
| **热请求延迟** | ~30-37ms | ~30-37ms |
| **Pod 缩零时间** | ~90s | ~90s |
| **第一个节点移除** | ~6min | ~6min |
| **所有节点移除** | ~15min | ~15min |

---

## 4. 官方文档参考

| 主题 | 链接 |
|------|------|
| OpenShift Serverless 概览 | https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37 |
| 安装 OpenShift Serverless | https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/installing_openshift_serverless/install-serverless-operator |
| Knative Serving | https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/serving/index |
| Knative Serving 自动扩缩 | https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/serving/autoscaling |
| Knative Eventing | https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/eventing/index |
| Knative Functions (kn func) | https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.37/html/functions/serverless-functions-setup |
| ROSA 机器池管理 | https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cluster_administration/managing-compute-nodes |
| Red Hat Build of Karpenter | https://aws.amazon.com/blogs/ibm-redhat/cut-costs-scale-smarter-with-rosa-karpenter-automates-compute-provisioning/ |
| Karpenter 上游文档 | https://karpenter.sh/docs/ |
| AWS Karpenter Best Practices | https://docs.aws.amazon.com/eks/latest/best-practices/karpenter.html |

---

## 5. 成功标准

| 标准 | 衡量方式 | 状态 |
|------|---------|------|
| Scale-to-Zero | Pod 数降至 0，节点被移除 | 已验证 |
| Spot 优先调度 | Pod 优先调度到 Spot 节点 | 已验证 |
| On-Demand 兜底 | Spot 不可用时自动使用 On-Demand | 已验证 |
| Spot 成本节省 | >=50% | 实测 55% |
| 冷启动（有节点） | < 10s | 实测 ~1.67s |
| 冷启动（零节点） | 已测量 | 实测 ~205s |
| 节点缩零 | 全部节点移除 | 实测 ~15min |
| 多云可移植 | 同一 YAML 多云部署 | 设计已验证 |
| Karpenter 就绪 | GA 后可平滑迁移 | 路径已规划 |
