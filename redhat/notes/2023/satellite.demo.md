# satellite simple demo

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