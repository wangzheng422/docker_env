# satellite 作为yum repo的简单演示

客户购买了 redhat rhel 订阅，想在国内使用，但是 rhel 订阅在os上激活，是需要连接国外服务器的，由于众所周知的原因，国内访问有时候不稳定，甚至国外服务器本身有的时候就慢，那么这种情况下，客户就需要一个订阅的代理服务器。红帽的satellite产品，就是这样一个订阅注册代理服务器。

当然，satellite产品内涵很丰富，订阅注册代理只是一个其中一个很小的功能。satellite产品的标准使用场景是，用户有一个内网环境，里面有一个主机能联网，这个主机安装satellite，并向satellite导入订阅证书，启动yum repo镜像服务，iPXE, dhcp, dns服务等，这些服务在一起，就能让内网的其他主机具备了上电以后，自动安装rhel的能力，rhel装好以后，satellite还提供持续更新的功能。

所以satellite是一个带安装源的OS全生命周期管理维护产品，官方文档在这里：
- https://access.redhat.com/documentation/en-us/red_hat_satellite/6.13

本文，就演示一个最简单的场景，安装satellite，并且内网rhel在satellite上激活订阅，并使用satellite作为yum repo源。

实验架构图：



```bash
# satellite server
# 172.21.6.171
# dns resolve and reverse to panlab-satellite-server.infra.wzhlab.top

# satellite client host
# 172.21.6.172

# on satellite server
ssh root@172.21.6.171

# https://access.redhat.com/documentation/en-us/red_hat_satellite/6.13/html-single/installing_satellite_server_in_a_connected_network_environment/index

systemctl disable --now firewalld.service

hostnamectl set-hostname panlab-satellite-server.infra.wzhlab.top

ping -c1 localhost
# PING localhost(localhost (::1)) 56 data bytes
# 64 bytes from localhost (::1): icmp_seq=1 ttl=64 time=0.043 ms

ping -c1 `hostname -f`
# PING panlab-satellite-server.wzhlab.top (172.21.6.171) 56(84) bytes of data.
# 64 bytes from bogon (172.21.6.171): icmp_seq=1 ttl=64 time=0.047 ms

subscription-manager register --auto-attach --username xxxxxxxxx --password xxxxxxxxxx

subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms \
  --enable=rhel-8-for-x86_64-appstream-rpms \
  --enable=satellite-6.13-for-rhel-8-x86_64-rpms \
  --enable=satellite-maintenance-6.13-for-rhel-8-x86_64-rpms
# Repository 'rhel-8-for-x86_64-baseos-rpms' is enabled for this system.
# Repository 'rhel-8-for-x86_64-appstream-rpms' is enabled for this system.
# Repository 'satellite-6.13-for-rhel-8-x86_64-rpms' is enabled for this system.
# Repository 'satellite-maintenance-6.13-for-rhel-8-x86_64-rpms' is enabled for this system.

dnf module enable satellite:el8

dnf update -y

dnf install satellite chrony sos -y

systemctl enable --now chronyd

satellite-installer --scenario satellite \
--foreman-initial-organization "My_Organization" \
--foreman-initial-location "My_Location" \
--foreman-initial-admin-username admin \
--foreman-initial-admin-password redhat
# ......
# 2023-05-16 22:41:17 [NOTICE] [configure] System configuration has finished.
#   Success!
#   * Satellite is running at https://panlab-satellite-server.infra.wzhlab.top
#       Initial credentials are admin / redhat

#   * To install an additional Capsule on separate machine continue by running:

#       capsule-certs-generate --foreman-proxy-fqdn "$CAPSULE" --certs-tar "/root/$CAPSULE-certs.tar"
#   * Capsule is running at https://panlab-satellite-server.infra.wzhlab.top:9090

#   The full log is at /var/log/foreman-installer/satellite.log
# Package versions are being locked.

```

![](imgs/2023-05-16-22-50-40.png)

![](imgs/2023-05-16-23-07-37.png)

export Subscription Manifest from redhat portal

![](imgs/2023-05-16-23-51-22.png)

![](imgs/2023-05-16-23-52-08.png)

![](imgs/2023-05-16-23-53-01.png)

![](imgs/2023-05-16-23-59-18.png)

![](imgs/2023-05-17-00-09-53.png)

![](imgs/2023-05-17-00-12-05.png)

![](imgs/2023-05-17-00-18-28.png)

![](imgs/2023-05-17-00-18-57.png)

![](imgs/2023-05-17-00-21-12.png)

![](imgs/2023-05-17-00-21-45.png)

![](imgs/2023-05-17-00-22-43.png)

![](imgs/2023-05-17-00-23-02.png)

![](imgs/2023-05-17-09-57-12.png)

![](imgs/2023-05-17-09-57-43.png)

![](imgs/2023-05-17-10-14-08.png)

```bash

satellite-maintain service list
# Running Service List
# ================================================================================
# List applicable services:
# dynflow-sidekiq@.service                   indirect
# foreman-proxy.service                      enabled
# foreman.service                            enabled
# httpd.service                              enabled
# postgresql.service                         enabled
# pulpcore-api.service                       enabled
# pulpcore-content.service                   enabled
# pulpcore-worker@.service                   indirect
# redis.service                              enabled
# tomcat.service                             enabled

# All services listed                                                   [OK]
# --------------------------------------------------------------------------------

```

![](imgs/2023-05-17-11-18-07.png)

![](imgs/2023-05-17-11-18-38.png)

![](imgs/2023-05-17-12-42-56.png)

![](imgs/2023-05-17-12-43-39.png)

![](imgs/2023-05-17-12-47-33.png)

![](imgs/2023-05-17-12-48-05.png)

![](imgs/2023-05-17-12-50-16.png)

![](imgs/2023-05-17-13-24-23.png)




<!-- ![](imgs/2023-05-17-13-24-53.png) -->



![](imgs/2023-05-17-13-28-04.png)

![](imgs/2023-05-17-13-28-36.png)


![](imgs/2023-05-17-14-33-41.png)

```bash
df -h
# Filesystem      Size  Used Avail Use% Mounted on
# devtmpfs         16G     0   16G   0% /dev
# tmpfs            16G  148K   16G   1% /dev/shm
# tmpfs            16G  8.9M   16G   1% /run
# tmpfs            16G     0   16G   0% /sys/fs/cgroup
# /dev/sda3       499G  106G  393G  22% /
# /dev/sda2      1014M  265M  749M  27% /boot
# /dev/sda1       599M  9.6M  590M   2% /boot/efi
# tmpfs           3.2G     0  3.2G   0% /run/user/0

free -h
#               total        used        free      shared  buff/cache   available
# Mem:           31Gi        21Gi       1.7Gi       567Mi       7.9Gi       8.6Gi
# Swap:            0B          0B          0B

```

![](imgs/2023-05-17-14-35-06.png)

```bash
# on client host

curl -sS --insecure 'https://panlab-satellite-server.infra.wzhlab.top/register?activation_keys=demo-activate&location_id=2&organization_id=1&setup_insights=false&setup_remote_execution=false&setup_remote_execution_pull=false&update_packages=false' -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0LCJpYXQiOjE2ODQzMDU1MTYsImp0aSI6IjdiODBkNzdmMjVjYzY1MDZjODQ3OGI2Y2VjNzRkZWZjOGM2YjAyMDUxMDQ4YTcyYTJlMWE1YzRiNTgyMjE5NzAiLCJzY29wZSI6InJlZ2lzdHJhdGlvbiNnbG9iYWwgcmVnaXN0cmF0aW9uI2hvc3QifQ.EVXyW9gjWyAQIFYUxnwwdxAigrPmUo_XYWnqn-Wh1Fw' | bash

# #
# # Running registration
# #
# Updating Subscription Management repositories.
# Unable to read consumer identity

# This system is not registered with an entitlement server. You can use subscription-manager to register.

# Error: There are no enabled repositories in "/etc/yum.repos.d", "/etc/yum/repos.d", "/etc/distro.repos.d".
# The system has been registered with ID: e9d03372-d3f4-4970-bb38-3a2282458e29
# The registered system name is: panlab-satellite-client
# Installed Product Current Status:
# Product Name: Red Hat Enterprise Linux for x86_64
# Status:       Subscribed

# # Running [panlab-satellite-client] host initial configuration
# Refreshing subscription data
# All local data refreshed
# Host [panlab-satellite-client] successfully configured.
# Successfully updated the system facts.

subscription-manager status
# +-------------------------------------------+
#    System Status Details
# +-------------------------------------------+
# Overall Status: Current

# System Purpose Status: Not Specified

subscription-manager release --list
# +-------------------------------------------+
#           Available Releases
# +-------------------------------------------+
# 8.6

subscription-manager release --set=8.6

subscription-manager config
# [server]
#    hostname = panlab-satellite-server.infra.wzhlab.top
# ......
# [rhsm]
#    auto_enable_yum_plugins = [1]
#    baseurl = https://panlab-satellite-server.infra.wzhlab.top/pulp/content
# ......

dnf repolist
# Updating Subscription Management repositories.
# repo id                                                                   repo name
# rhel-8-for-x86_64-appstream-rpms                                          Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
# rhel-8-for-x86_64-baseos-rpms                                             Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)

dnf makecache
# Updating Subscription Management repositories.
# Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)                                                                                       63 kB/s | 4.1 kB     00:00
# Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)                                                                                    65 kB/s | 4.5 kB     00:00
# Metadata cache created.

subscription-manager repos
# +----------------------------------------------------------+
#     Available Repositories in /etc/yum.repos.d/redhat.repo
# +----------------------------------------------------------+
# Repo ID:   rhel-8-for-x86_64-baseos-rpms
# Repo Name: Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
# Repo URL:  https://panlab-satellite-server.infra.wzhlab.top/pulp/content/My_Organization/Library/content/dist/rhel8/8.6/x86_64/baseos/os
# Enabled:   1

# Repo ID:   rhel-8-for-x86_64-appstream-rpms
# Repo Name: Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
# Repo URL:  https://panlab-satellite-server.infra.wzhlab.top/pulp/content/My_Organization/Library/content/dist/rhel8/8.6/x86_64/appstream/os
# Enabled:   1


```

![](imgs/2023-05-17-14-56-51.png)

![](imgs/2023-05-17-14-58-08.png)

![](imgs/2023-05-17-15-00-11.png)

![](imgs/2023-05-17-15-00-22.png)

![](imgs/2023-05-17-15-00-55.png)

![](imgs/2023-05-17-15-09-56.png)

![](imgs/2023-05-17-15-14-52.png)

![](imgs/2023-05-17-15-15-23.png)

![](imgs/2023-05-17-15-15-46.png)

![](imgs/2023-05-17-15-16-44.png)

![](imgs/2023-05-17-15-17-41.png)

![](imgs/2023-05-17-15-18-46.png)

![](imgs/2023-05-17-15-26-21.png)

![](imgs/2023-05-17-15-27-14.png)

![](imgs/2023-05-17-15-28-45.png)

![](imgs/2023-05-17-15-29-32.png)

```bash
# on satellite-client
dnf update -y

```

![](imgs/2023-05-17-18-18-48.png)

```bash
# on client-02 , to try over use
curl -sS --insecure 'https://panlab-satellite-server.infra.wzhlab.top/register?activation_keys=demo-activate&location_id=2&organization_id=1&setup_insights=false&setup_remote_execution=false&setup_remote_execution_pull=false&update_packages=false' -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0LCJpYXQiOjE2ODQzMDU1MTYsImp0aSI6IjdiODBkNzdmMjVjYzY1MDZjODQ3OGI2Y2VjNzRkZWZjOGM2YjAyMDUxMDQ4YTcyYTJlMWE1YzRiNTgyMjE5NzAiLCJzY29wZSI6InJlZ2lzdHJhdGlvbiNnbG9iYWwgcmVnaXN0cmF0aW9uI2hvc3QifQ.EVXyW9gjWyAQIFYUxnwwdxAigrPmUo_XYWnqn-Wh1Fw' | bash
# #
# # Running registration
# #
# Updating Subscription Management repositories.
# Unable to read consumer identity

# This system is not registered with an entitlement server. You can use subscription-manager to register.

# Error: There are no enabled repositories in "/etc/yum.repos.d", "/etc/yum/repos.d", "/etc/distro.repos.d".
# The system has been registered with ID: 43e38f76-2416-49db-890f-1a3ad3973828
# The registered system name is: satellite-client-02
# Installed Product Current Status:
# Product Name: Red Hat Enterprise Linux for x86_64
# Status:       Not Subscribed

# Unable to find available subscriptions for all your installed products.

subscription-manager list --consumed
# No consumed subscription pools were found.

subscription-manager repos
# This system has no repositories available through subscriptions.

subscription-manager status
# +-------------------------------------------+
#    System Status Details
# +-------------------------------------------+
# Overall Status: Invalid

# Red Hat Enterprise Linux for x86_64:
# - Not supported by a valid subscription.

# System Purpose Status: Not Specified
```

![](imgs/2023-05-17-19-00-41.png)

![](imgs/2023-05-17-19-10-32.png)

![](imgs/2023-05-17-19-12-23.png)

if we enable SCA, and limit the active key host number, what happend?

![](imgs/2023-05-17-20-05-11.png)

![](imgs/2023-05-17-20-05-56.png)

```bash
# on client-02 , to try over use
curl -sS --insecure 'https://panlab-satellite-server.infra.wzhlab.top/register?activation_keys=demo-activate&location_id=2&organization_id=1&setup_insights=false&setup_remote_execution=false&setup_remote_execution_pull=false&update_packages=false' -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0LCJpYXQiOjE2ODQzMDU1MTYsImp0aSI6IjdiODBkNzdmMjVjYzY1MDZjODQ3OGI2Y2VjNzRkZWZjOGM2YjAyMDUxMDQ4YTcyYTJlMWE1YzRiNTgyMjE5NzAiLCJzY29wZSI6InJlZ2lzdHJhdGlvbiNnbG9iYWwgcmVnaXN0cmF0aW9uI2hvc3QifQ.EVXyW9gjWyAQIFYUxnwwdxAigrPmUo_XYWnqn-Wh1Fw' | bash
# #
# # Running registration
# #
# Updating Subscription Management repositories.
# Unable to read consumer identity

# This system is not registered with an entitlement server. You can use subscription-manager to register.

# Error: There are no enabled repositories in "/etc/yum.repos.d", "/etc/yum/repos.d", "/etc/distro.repos.d".
# Max Hosts (1) reached for activation key 'demo-activate' (HTTP error code 409: Conflict)

```