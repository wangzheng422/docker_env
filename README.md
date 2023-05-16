[![github pages](https://github.com/wangzheng422/docker_env/actions/workflows/gh-pages.yml/badge.svg)](https://github.com/wangzheng422/docker_env/actions/workflows/gh-pages.yml)
# 仓库说明

本仓库是作者在日常系统操作中的技术笔记。作者平日有些机会进行很多系统操作，包括很多PoC，新系统验证，方案探索工作，所以会有很多系统实际操作的机会，涉及到操作系统安装，iaas, paas平台搭建，中间件系统验证，应用系统的开发和验证。很多操作步骤比较复杂，所以需要一个地方进行集中的笔记记录，方便自己整理，并第一时间在线分享。

目前仓库中，有很多经验分享，其中的一些文章，比较有用：
- openshift4 安装系列
  - [如何获得 openshift4 免费下载密钥](redhat/ocp4/4.5/4.5.ocp.pull.secret.md)
  - [openshift4 离线安装介质的制作](redhat/ocp4/4.6/4.6.build.dist.md)
  - [openshift4 rhel7物理机 baremetal UPI模式 离线安装](redhat/ocp4/4.6/4.6.disconnect.bm.upi.static.ip.on.rhel7.md)
  - [openshift4 rhel8物理机 baremetal UPI模式 离线安装](redhat/ocp4/4.6/4.6.disconnect.bm.upi.static.ip.on.rhel8.md)
  - [openshift4 物理机 baremetal IPI模式 离线安装 单网络模式](redhat/ocp4/4.6/4.6.disconnect.bm.ipi.on.rhel8.md)
  - [openshift4 物理机 baremetal IPI模式 离线安装 双网络模式](redhat/ocp4/4.6/4.6.disconnect.bm.ipi.on.rhel8.provisionning.network.md)
  - [nvidia gpu for openshift 4.6 disconnected 英伟达GPU离线安装](redhat/ocp4/4.6/4.6.nvidia.gpu.disconnected.md)
  - [openshift4 初始安装后 补充镜像](redhat/ocp4/4.6/4.6.add.image.md)
  - [openshift4 补充samples operator 需要的 image stream](redhat/ocp4/4.5/4.5.is.sample.md)
  - [openshift4 calico 离线部署](redhat/ocp4/4.3/4.3.calico.md)
  - [openshift4 尝鲜 cilium CNI](redhat/ocp4/4.6/4.6.cilium.md)
  - [openshift4 集群升级](redhat/ocp4/4.2/4.2.upgrade.md)
  - [缩小根分区 / sysroot 的大小](redhat/ocp4/4.8/4.8.shrink.sysroot.md)
  - [部署升级服务 完善离线升级功能](redhat/ocp4/4.8/4.8.update.service.md)
  - [添加 win10 worker 节点](redhat/ocp4/4.8/4.8.windows.node.md)
  - [2022.02 assist install 联线模式下 单节点ocp 无需dhcp 静态ip部署](redhat/ocp4/4.9/4.9.sno.static.ip.local.assisted.connected.md)
  - [2022.02 assist install 离线模式下 单节点ocp 无需dhcp 静态ip部署](redhat/ocp4/4.9/4.9.sno.static.ip.local.assisted.disconnected.md)
  - [单节点ocp 安装 无需dhcp 静态ip部署](redhat/ocp4/4.9/4.9.4.9.sno.using.bootstrap.disconnected.md)
  - [2022.04 IPI模式 单节点 离线 单网络模式 安装](redhat/ocp4/4.10/4.10.disconnect.bm.ipi.sno.static.ip.md)
  - [2022.04 ACM zero touch provision 远程单节点集群 全自动安装](redhat/ocp4/4.10/4.10.acm.ztp.disconnected.auto.md)
  - [2022.04 coreos 启动和分区挂载分析](redhat/ocp4/4.10/4.10.coreos.boot.md)
  - [2022.05 openshift4 单节点 命令行安装](redhat/ocp4/4.10/4.10.sno.installer.md)
  - [2022.05 openshift4 单节点 在第一块硬盘上添加更多分区](redhat/ocp4/4.10/4.10.sno.partition.quay.md)
  - [2022.05 openshift4 单节点 使用 lvm 和 nfs 在集群内提供存储](redhat/ocp4/4.10/4.10.sno.nfs.lvm.md)
  - [2022.05 openshift4 单节点 从centos7/8 开始安装](redhat/ocp4/4.10/4.10.sno.boot.from.linux.md)
  - [2022.05 openshift4 单节点 安装精简版 ODF/ceph](redhat/ocp4/4.10/4.10.sno.odf.md)
  - [2022.08 定制 rhcos](redhat/ocp4/4.10/4.10.replace.coreos.md)
  - [2022.08 rhcos 里面安装 rpm](redhat/ocp4/4.10/4.10.rpm-ostree.install.md)
  - [2022.09 openshift 4 组件版本](redhat/ocp4/4.10/4.10.component.version.md)
  - [2022.09 内嵌 dns, haproxy, registrty](redhat/ocp4/4.10/4.10.embeded.dns.haproxy.registry.md)
  - [2022.12 升级 openshift 4.10 内核到 rhel 9.1 支持 海光 x86 cpu](redhat/ocp4/4.10/4.10.replace.coreos.rhel.9.0.md)
  - [2023.01 使用 hypershift 安装控制面托管的 openshift 集群](redhat/ocp4/4.11/4.11.acm.hypershift.md)
  - [2023.04 使用 agent based installer 安装 3 节点集群](redhat/ocp4/4.12/4.12.3node.upi.agent.md)
  - [2023.04 使用 agent based installer 安装 单节点集群](redhat/ocp4/4.12/4.12.single.node.upi.agent.md)
  - [2023.05 在 openshift 内部编译内核驱动 rpm 并使用](redhat/ocp4/4.12/4.12.ocp.driver.build.md)
  - [2023.05 替换 rhcos 为 openAnolis 支持国产操作系统](redhat/ocp4/4.10/4.10.replace.coreos.to.anolis.md)
- openshift4 使用系列
  - [2022.11 在 openshift 4.11 上安装和运行 openstack](redhat/ocp4/4.11/4.11.3node.ipi.for.osp.prod.md)
  - [2022.06 在 openshift4 上运行 OpenRAN 无线基站应用](redhat/ocp4/4.10/4.10.flexran.20.11.pf.deploy.md)
  - [2022.05 openshift4 可视化 ovs netflow](redhat/ocp4/4.10/4.10.netflow.table.md)
  - [2022.05 intel o-ran flexran 方案在openshift4上的安装和使用](redhat/ocp4/4.10/4.10.flexran.20.11.md)
  - [2022.01 ci/cd pipeline gitops演示](redhat/ocp4/4.9/4.9.ci.cd.demo.md)
  - [2021.12 oc exec 原理分析](redhat/ocp4/4.9/4.9.oc.exec.md)
  - [2021.12 nf_conntrack 在 openshift4.9上的处理](redhat/ocp4/4.9/4.9.nf.conntrack.md)
  - [2021.12 加载第三方设备驱动](redhat/ocp4/4.9/4.9.load.3rd.part.driver.md)
  - [2021.12 helm chart/helm operator](https://github.com/wangzheng422/baicell-helm-operator)
  - [使用 MetalLB 用 Layer2 发布 LoadBalancer](redhat/ocp4/4.8/4.8.metalb.l2.md)
  - [使用 MetalLB 用 BGP 发布 LoadBalancer](redhat/ocp4/4.8/4.8.metalb.md)
  - [kata / 沙盒容器](redhat/ocp4/4.8/4.8.kata.md)
  - [在非官方支持的网卡上，测试SRIOV/DPDK](redhat/ocp4/4.7/4.7.sriov.md)
  - [使用 keepalived 激活 LoadBalancer 服务类型](redhat/ocp4/4.7/4.7.keepalived.operator.md)
  - [在节点上启用实时操作系统 real-time kernel](redhat/ocp4/4.7/4.7.real-time.kernel.md)
  - [从容器向宿主机注入内核模块 kmod / driver](redhat/ocp4/4.7/4.7.install.kmod.driver.md)
  - [GPU/vGPU 共享](redhat/ocp4/4.6/4.6.vgpu.sharing.deploy.md)
  - [openshift headless service讲解](redhat/ocp4/4.4/4.4.headless.service.md)
  - [openshift volumn 存储的各种测试](redhat/ocp4/4.3/4.3.volumn.md)
  - [openshift 设置 SupportPodPidsLimit 解除 pids 限制](redhat/ocp4/4.3/4.3.SupportPodPidsLimit.md)
  - [openshift4 配置 SSO 点单认证](redhat/ocp4/4.3/4.3.sso.md)
  - [openshift4 SCC 相关安全能力测试](redhat/ocp4/4.3/4.3.scc.md)
  - [openshift4 从 node not ready 状态恢复](redhat/ocp4/4.3/4.3.recover.node.not.ready.md)
  - [openshift4 QoS 能力](redhat/ocp4/4.3/4.3.QoS.nic.md)
  - [openshift4 QoS 在流量压力下的表现](redhat/ocp4/4.3/4.3.QoS.nic.high.md)
  - [openshift4 使用 image proxy 来下载镜像](redhat/ocp4/4.3/4.3.proxy.md)
  - [openshift4 NUMA 绑核测试](redhat/ocp4/4.3/4.3.numa.md)
  - [openshift4 Network Policy 测试](redhat/ocp4/4.3/4.3.network.policy.md)
  - [openshift4 网络多播 测试](redhat/ocp4/4.3/4.3.multicast.md)
  - [openshift4 配置节点防火墙](redhat/ocp4/4.3/4.3.firewall.md)
  - [openshift4 集成 ldap](redhat/ocp4/4.3/4.3.ldap.md)
  - [openshift4 维护 image pull secret](redhat/ocp4/4.3/4.3.image.pull.md)
  - [openshift4 使用大页内存 huge page](redhat/ocp4/4.3/4.3.huge.page.md)
  - [openshift4 使用 helm](redhat/ocp4/4.3/4.3.helm.md)
  - [openshift4 定制router 支持 TCP ingress](redhat/ocp4/4.3/4.3.haproxy.md)
  - [openshift4 监控能力展示 grafana](redhat/ocp4/4.3/4.3.grafana.md)
  - [openshift4 CPU 绑核 测试](redhat/ocp4/4.3/4.3.cpu.manager.md)
  - [openshift4 build config & hpa 自动化编译和自动扩缩容](redhat/ocp4/4.3/4.3.build.config.md)
- 应用上云系列教程 CCN
  - [应用上云系列教程 containerized cloud native (CCN) for openshift 4.4](redhat/ocp4/4.4/4.4.ccn.devops.deploy.md)
  - [CCN 安装介质制作 for openshift 4.4](redhat/ocp4/4.4/4.4.ccn.devops.build.md)
  - [应用上云系列教程 containerized cloud native (CCN) for openshift 4.6](redhat/ocp4/4.6/4.6.ccn.devops.deploy.md)
  - [CCN 安装介质制作 for openshift 4.6](redhat/ocp4/4.6/4.6.ccn.devops.build.md)
- 红帽其他产品系列
  - [2022.05 ACM observability for openshift 4.10](redhat/ocp4/4.10/4.10.acm.observ.md)
  - [2022.01 离线安装 ansible platform](redhat/notes/2022/2022.01.ansible.install.md)
  - [2021.12 RHACS 应对log4j 原理和实践](redhat/notes/2021/2021.08.virus.md)
  - [openshift承载虚拟化业务(CNV)](redhat/ocp4/4.5/4.5.ocp.ocs.cnv.ceph.md)
  - [RHACS / stackrox](redhat/ocp4/4.7/4.7.rhacs.md)
  - [为 RHACS 找个应用场景： 安全合规测试云](redhat/ocp4/4.7/4.7.rhacs.deep.md)
- 操作系统相关
  - [2023.04 RHEL 订阅在线注册相关问题](redhat/notes/2023/rhel.subscription.register.md)
  - [2022.12 通过新增系统启动项来原地重装操作系统](redhat/notes/2022/2022.12.boot.to.install.md)
  - [2022.04 Relax and Recover(ReaR) 系统备份和灾难恢复](redhat/notes/2022/2022.04.os.backup.ReaR.md)
  - [2022.04 红帽免费的开发者订阅申请和使用](redhat/notes/2022/2022.04.no-cost.rhel.sub.md)
  - [2022.01 在红帽官网查询rpm属于哪个repo](redhat/notes/2022/2022.01.rpm.belongs.md)
  - [2022.01 离线环境下 原地升级 rhel7->rhel8](redhat/notes/2022/2022.01.rhel7.upgrade.to.rhel8.md)
  - [2022.01 系统启动自动加载sysctl配置](redhat/notes/2022/2022.01.sysctl.md)
  - [2021.12 Mellanox BF2 刷固件并测试DPI URL-filter场景](redhat/notes/2021/2021.12.ocp.bf2.dpi.url.filter.md)
  - [2021.11 mellanox BF2 网卡激活snap功能， 配置nvme over fabrics 支持](redhat/notes/2021/2021.11.bf2.snap.try.md)
  - [2021.11 Mellanox CX6 vdpa 硬件卸载 ovs-kernel 方式](redhat/notes/2021/2021.10.cx6dx.vdpa.offload.md)
  - [RHEL8编译定制化内核](redhat/rhel/rhel.build.kernel.md)
  - [检查OS是否是运行在虚拟机上](redhat/ocp4/4.5/4.5.check.whether.vm.md)
  - [两个主机用ovs组网](redhat/ocp4/4.4/4.4.ovs.md)
  - [CentOS Stream是什么](https://www.bilibili.com/video/BV1Go4y1o7hn/)
- 优秀的workshop
  - [openshift4 & openshift storage workshop](redhat/ocp4/4.5/4.5.ocp.ocs.workshop.md)
- POC
  - [2020.04 某次POC openshift LVM调优](redhat/ocp4/4.3/poc.sc/install.poc.sc.md)
- OSX使用技巧
  - [如何录制系统声音](redhat/osx/osx.record.system.audio.md)

作者还做了一个[chrome extension](https://chrome.google.com/webstore/detail/bing-image-new-tab/hahpccmdkmgmaoebhfnkpcnndnklfbpj/)，用来在new tab上展示bing.com的美图，简单美观，欢迎使用。

[<kbd><img src="imgs/2021-01-17-17-29-10.png" width="600"></kbd>](https://chrome.google.com/webstore/detail/bing-image-new-tab/hahpccmdkmgmaoebhfnkpcnndnklfbpj/)

作者还有很多视频演示，欢迎前往作者的频道订阅
- [bilibili](https://space.bilibili.com/19536819)
- [youtube](https://www.youtube.com/user/wangzheng422)
<!-- - [西瓜视频](https://www.ixigua.com/home/1134309560818120) -->

<!-- 作者正在写一本在线书[《OpenShift4 一步一脚印》](https://wangzheng422.github.io/openshift4-steps-book/introduction.html)。 -->

最后，欢迎支持关注作者B站

[<kbd><img src="imgs/2021-05-09-21-47-36.png" width="600"></kbd>](https://space.bilibili.com/19536819)

# 许可证
项目中涉及代码采用GNU V3许可。

# 版权声明
本项目遵循 **[CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)** 协议。**商业转载必须征求作者 wangzheng422 授权同意，转载请务必注明[出处](https://github.com/wangzheng422/docker_env)。** 作者保留最终解释权及法律追究权力。