# openshift4 实施过程中的几个问题探讨

# NTP服务协同

客户的问题是这样的，在VM时代，客户停用了vm里面的ntpd/chronyd，自己实现了一套ntp服务，通过这个自研的ntp服务，客户的应用就可以得到vm里面时钟更新的消息，并根据这个消息，做应用层的处理。但是在openshift4这种云平台这里，所有的pod，都共享node上的chronyd服务，那pod里面的应用，就无法拿到时钟更新信息。

我们的解决思路是，在node上的chronyd做配置，让它把时钟更新信息输出到日志，pod挂载这个日志，从而读取到时钟更新信息。

# node上硬件信息

问题：客户的软件需要检查当前pod绑定的vcpu对应的是哪些物理cpu core，哪些numa node，pod绑定的网卡，对应那些numa node，如果对应错误，需要报警。但是pod又是低权限运行，无法拿到。

解决思路：使用init container，高权限运行，lstopo的结果输出到一个volumn，把这个volumn共享给低权限业务pod即可。

# 指定vcpu, cpu core, numa node, nic 绑定

问题：客户要求，pod能指定cpu core, numa node, nic来运行。要保证分配给pod的vcpu，都在一个cpu core上。

解决思路：openshift4有PerformanceProfile，会整合cpu manager, topology manager，来保证vcpu, cpu core, numa node绑定，其中vcpu绑定相同的物理core，是自动开启full-pcpus-only实现。另外，还有NUMA Resources Operator，来保证nic和numa node绑定。

如果我们给系统添加以下配置：
```yaml
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
 name: performance
spec:
  cpu:
    reserved: "0-3"
    isolated: "4-15"
  numa:
    topologyPolicy: "single-numa-node"
  nodeSelector:
    node-role.kubernetes.io/worker: ""
```
我们可以看到，kubelet.conf 会自动添加一些配置。
```bash
[root@ip-10-0-229-114 kubernetes]# cat kubelet.conf | grep -i cpu
  "cpuManagerPolicy": "static",
  "cpuManagerPolicyOptions": {
    "full-pcpus-only": "true"
  "cpuManagerReconcilePeriod": "5s",
  "reservedSystemCPUs": "0-3",
```