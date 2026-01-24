# OVN Egress IP Controller

## 概述

这是一个增强版的 Kubernetes Controller,用于自动化管理 OVN 网络配置,支持自定义 Egress IP 解决方案。

## 主要功能

### 1. APB 路由同步
- 监控 Gateway Pod 的状态变化
- 自动更新 `AdminPolicyBasedExternalRoute` 资源的 `nextHops` 字段
- 确保路由始终指向当前运行的 Gateway Pod IP

### 2. Gateway Pod OVN 配置
当 Gateway Pod 创建或重启时,自动执行:
- **清除 Port Security**: 允许 Gateway Pod 转发来自其他 Pod 的流量
- **添加 Stateless ACLs**: 
  - Priority 31821 的 `from-lport` 规则(允许所有出站流量)
  - Priority 31821 的 `to-lport` 规则(允许所有入站流量)

### 3. Business Pod OVN 配置
当 Business Pod 创建或重启时,自动执行:
- **保留 Port Security**: 维持安全性,只允许发送自己的流量
- **添加 Stateless ACLs**: 
  - Priority 31821 的 `from-lport` 规则(允许所有出站流量)
  - Priority 31821 的 `to-lport` 规则(允许所有入站返回流量)

### 4. 自动清理
- 在应用新配置前,自动清理旧的 ACL 规则
- 幂等操作,可安全重复执行
- Pod 删除时,OVN 配置自动清理

## 工作原理

### OVN 命令执行
Controller 通过以下方式执行 OVN 命令:
1. 根据目标 Pod 所在的 Node,找到对应的 `ovnkube-node` Pod
2. 使用 `oc exec` 在 `ovn-controller` 容器中执行命令
3. 这确保了命令在正确的 OVN 数据库实例上执行

### Watch 机制
Controller 同时监听三类资源:
- **Gateway Pods**: 触发 APB 同步和 Gateway OVN 配置
- **Business Pods**: 触发 Business Pod OVN 配置
- **APB Resources**: 防止手动修改,强制保持一致性

### 幂等性保证
- APB 更新前会对比当前状态和期望状态
- 只有在不一致时才执行更新
- 防止 Watch 事件触发的无限循环

## 配置说明

### 环境变量 (可在代码中修改)

```python
# Gateway 配置
GATEWAY_NAMESPACE = "ns-egress-infra"  # Gateway Pod 所在的命名空间
GATEWAY_LABEL = "app=ns-blue-gateway"  # Gateway Pod 的标签选择器

# Business Pod 配置
BUSINESS_NAMESPACE = "ns-blue"         # Business Pod 所在的命名空间
BUSINESS_LABEL = "app=business-app"    # Business Pod 的标签选择器

# APB 配置
APB_NAME = "ns-blue-route"             # AdminPolicyBasedExternalRoute 资源名称

# OVN 配置
OVN_ACL_PRIORITY = 31821               # 自定义 ACL 优先级
```

## 部署要求

### 1. RBAC 权限
Controller 需要以下权限:

```yaml
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: ["k8s.ovn.org"]
  resources: ["adminpolicybasedexternalroutes"]
  verbs: ["get", "list", "watch", "patch", "update"]
```

### 2. Python 依赖
- `kubernetes` Python 库

### 3. 集群访问
- 需要能够访问 `openshift-ovn-kubernetes` 命名空间
- 需要能够执行 `oc` 命令(通过 subprocess)

## 使用方法

### 部署 Controller

```bash
# 1. 创建 ConfigMap
oc create configmap apb-script \
  --from-file=files/ovn.egressip/controller.py \
  -n ns-egress-infra

# 2. 部署 Controller
oc apply -f controller-deployment.yaml
```

### 查看日志

```bash
# 查看 Controller 日志
oc logs -f deployment/apb-controller -n ns-egress-infra

# 预期输出示例:
# ============================================================
# OVN Egress IP Controller Starting...
# ============================================================
# Loaded in-cluster configuration
# 
# [Initial Sync] Performing initial APB reconciliation...
# Detect deviation! Desired: ['10.128.2.15'], Current in APB: ['192.168.99.1']. Correcting...
# APB Successfully enforced.
# 
# [Initial Sync] Applying OVN patches to existing pods...
# ============================================================
# Cleaning Pod [app=ns-blue-gateway] in Namespace [ns-egress-infra]
#   Target: Pod=ns-blue-gateway-xxx | Node=worker-01-demo | LSP=ns-egress-infra_ns-blue-gateway-xxx
#   >> Cleaning up ACLs (Priority 31821) for ns-egress-infra_ns-blue-gateway-xxx...
#   Clean Done.
# ============================================================
# Configuring Pod [app=ns-blue-gateway] in Namespace [ns-egress-infra]
#   Port Security Mode: clear_port_security
#   Target: Pod=ns-blue-gateway-xxx | Node=worker-01-demo | LSP=ns-egress-infra_ns-blue-gateway-xxx
#   >> Clearing Port Security (Gateway mode - allows forwarding)...
#   >> Adding 'from-lport' stateless allow rule (Priority 31821)...
#   >> Adding 'to-lport' stateless allow rule (Priority 31821)...
#   Done.
```

## 故障排查

### Controller 无法执行 OVN 命令
检查 RBAC 权限:
```bash
oc auth can-i create pods/exec --as=system:serviceaccount:ns-egress-infra:apb-syncer
```

### Pod 配置未自动应用
1. 检查 Pod 标签是否匹配配置的选择器
2. 检查 Pod 是否处于 Running 状态
3. 查看 Controller 日志确认是否收到 Watch 事件

### ACL 规则冲突
如果发现 ACL 规则冲突,可以手动清理:
```bash
# 在对应的 ovnkube-node pod 中执行
ovn-nbctl find ACL priority=31821
ovn-nbctl remove Logical_Switch <node-name> acls <acl-uuid>
```

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    OVN Egress IP Controller                  │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Gateway    │  │   Business   │  │     APB      │      │
│  │ Pod Watcher  │  │ Pod Watcher  │  │   Watcher    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                   ┌────────▼────────┐                        │
│                   │  Reconcile APB  │                        │
│                   │  + Apply OVN    │                        │
│                   └────────┬────────┘                        │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
         ┌──────▼──────┐          ┌──────▼──────┐
         │ APB Resource│          │  OVN NBCtl  │
         │   (K8s API) │          │  (via exec) │
         └─────────────┘          └─────────────┘
```

## 注意事项

1. **优先级选择**: 使用 31821 作为自定义 ACL 优先级,避免与 OVN 默认规则冲突
2. **Stateless ACLs**: 所有流量使用 stateless 处理,因为返回流量的源 IP 可能与原始目标 IP 不同
3. **Port Security**: 
   - Gateway Pod 必须清除 Port Security 才能转发流量
   - Business Pod 保留 Port Security 以维持安全性
4. **幂等性**: 所有操作都是幂等的,可以安全地重复执行

## 许可证

本项目用于 OpenShift OVN Egress IP 限制的临时解决方案。
