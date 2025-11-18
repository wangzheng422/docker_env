# 使用 L4 交换机作为 Ingress 网关的高可用性方案

本文档提供了一个完整的解决方案，用于解决在 OpenShift 4.19 及更高版本中，当使用仅支持 L4 (TCP) 健康检查的负载均衡器时，如何确保 Ingress Router Pod 迁移或故障期间的零停机时间。

## 问题背景

标准的 OpenShift Router Pods (基于 HAProxy) 需要一个 L7 负载均衡器来正确分发流量。L7 负载均衡器可以通过访问 Router 的 `/healthz` 端点来精确判断其健康状况。然而，在许多生产环境中，只提供 L4 负载均衡器。

L4 负载均衡器只能进行 TCP 存活检查。当 Router Pod 迁移到另一个节点时（例如，在节点维护或 Pod 故障后），L4 负载均衡器无法立即感知到变化。它会继续将流量发送到旧节点的 IP，直到 TCP 连接超时，这期间会导致服务中断。

## 解决方案

我们采用“旁路健康检查”(Sibling Health Check) 模式来解决此问题。核心思想是：

1.  部署一个 `DaemonSet`，确保在每个运行 Router Pod 的节点上，都有一个我们的辅助 Pod (旁路 Pod)。
2.  这个旁路 Pod 运行在主机网络 (`hostNetwork`) 中。
3.  它会持续对**本地**的 Router Pod 进行 L7 健康检查 (访问 `localhost:1936/healthz`)。
4.  旁路 Pod 自己会监听一个 TCP 端口（例如 `18898`）。
    -   如果 L7 检查**成功**，则 `18898` 端口保持监听状态。
    -   如果 L7 检查**失败**，则**立即关闭** `18898` 端口，不等待任何现有连接。
5.  一个**外部的 L4 负载均衡器**（在本 Demo 中由本地 Docker 容器模拟）不再直接检查 Router Pod，而是检查旁路 Pod 在各个节点上暴露的 `18898` 端口。

通过这种方式，我们将 L7 的健康状态“翻译”成了 L4 负载均衡器可以即时感知的 TCP 端口的通断，从而实现流量的快速切换。

## 如何运行此 Demo

该测试将使用 Docker 在您的本地机器上运行一个 HAProxy 实例，以真实地模拟一个外部负载均衡器。

1.  **准备工作:**
    -   登录到您的 OpenShift 集群。
    -   确保您有权限创建 `Namespace`、`Deployment`、`DaemonSet` 等资源。
    -   确保 `oc`, `docker`, `docker-compose`, 和 `ab` (Apache Bench) 命令行工具可用，并且 Docker 服务正在运行。

2.  **执行测试:**
    ```bash
    chmod +x run_test.sh
    ./run_test.sh
    ```
    脚本将自动、分阶段地完成以下任务：
    - **部署应用**: 在 OpenShift 上创建测试应用和路由。
    - **测试阶段一 (L7 检查)**: 动态生成 HAProxy 配置，启动 Docker 容器，运行 `ab` 测试并模拟 Router 故障，最后清理容器。
    - **测试阶段二 (L4 检查)**: 重复上述过程，但使用 L4 健康检查配置来复现问题。
    - **测试阶段三 (解决方案)**: 部署旁路 `DaemonSet`，并配置 HAProxy 对旁路 Pod 的端口进行 L4 检查，运行测试以验证方案的有效性。
    - **自动清理**: 测试结束后，脚本会自动删除所有 OpenShift 资源和本地生成的配置文件。

## 文件清单

-   `01_namespace.yaml`: 为测试应用创建独立的命名空间。
-   `02_sample_app.yaml`: 部署一个简单的 Web 应用作为测试后端。
-   `03_route.yaml`: 为示例应用创建 OpenShift 路由。
-   `08_health_check_script_configmap.yaml`: 包含 Python 健康检查脚本的 `ConfigMap`。
-   `09_health_check_daemonset.yaml`: 部署旁路健康检查 Pod 的 `DaemonSet`。
-   `docker-compose.yml`: 用于在本地启动外部 HAProxy 容器。
-   `templates/`: 包含 HAProxy 配置文件模板的目录。
    -   `haproxy_l7.cfg.template`: L7 健康检查模板。
    -   `haproxy_l4.cfg.template`: L4 健康检查模板。
    -   `hapropy_l4_sidecar.cfg.template`: 针对旁路 Pod 的 L4 健康检查模板。
-   `run_test.sh`: 自动化执行所有测试阶段的 shell 脚本。
