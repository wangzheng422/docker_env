# 1 master 3 node

## 机器规划

```bash

cat << EOF >> ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrDP/5ASM1c/FqZVSCR3Pch/W7PH2mO7wBUGu/OO43/cQc+szxj8j07Ld1Onz+d4sxmYFdFYKH6gThRJEeFTmSm7+75Gdenmiqlq3lbCFuuX6x9WjgSadbYpaMEmTuZOSPniT3l3ny5wXyPof4MzhSbentwK50tnpe2bHPpIJ3PsxNWSSoMvSDoLJFMI67d48qbMs0WORpYCTjD+YLuQ4xXN1WOnxEEhwcvabUWNopiFv0d4I5gM8hYnFvA6VJF7m48fmz3msmWi1Im4R6DRYTOG/ZhYXBzHoc2PAoFApdZVQ1mD0012ortFj3VxgKHl9YbpmK4OSxWjZ90jPhRaWr root@ip-172-31-17-41.us-west-1.compute.internal
EOF

sudo -i

timedatectl set-timezone Asia/Shanghai

# localectl set-locale LANG=en_US.UTF-8

# cat << EOF > /etc/NetworkManager/conf.d/disable-resolve.conf-managing.conf
# [main]
# dns=none
# EOF

# cat << EOF >> /etc/resolv.conf
# nameserver 172.31.17.41
# EOF

# mkdir -p /etc/dnsmasq.d/
# cat > /etc/dnsmasq.d/origin-upstream-dns.conf << EOF 
# server=172.31.0.2
# EOF

# ntp
mv /etc/chrony.conf /etc/chrony.conf.bak
cat << EOF > /etc/chrony.conf

server 172.31.17.41
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony

EOF
systemctl restart chronyd

mkdir /etc/yum.repos.d.bak
mv -f /etc/yum.repos.d/* /etc/yum.repos.d.bak

cat << EOF > /etc/yum.repos.d/remote.repo
[remote]
name=RHEL FTP
baseurl=ftp://aws-yum.redhat.ren/yum
enabled=1
gpgcheck=0

EOF

yum clean all
yum repolist
yum -y install htop
yum -y update


# yum info <package name>
# yum list <package name>
# yum --showduplicates list <package name>
yum --showduplicates list ansible
yum downgrade ansible-2.6.17-1.el7ae
yum -y install ansible-2.6.17-1.el7ae openshift-ansible


```

## network

```bash


chronyc tracking
chronyc sources -v
chronyc sourcestats -v
chronyc makestep


# 172.31.18.62
hostnamectl set-hostname aws-m1.redhat.ren
# nmcli connection modify "System eth0" ipv4.method manual
nmcli connection modify "System eth0" ipv4.dns 172.31.17.41
# nmcli connection modify "System eth0" connection.autoconnect yes
# nmcli connection reload
# nmcli connection up "System eth0"

# 172.31.31.155
hostnamectl set-hostname aws-n1.redhat.ren
# nmcli connection modify eth0 ipv4.method manual
# nmcli connection modify eth0 ipv4.dns 192.168.122.111
# nmcli connection modify eth0 connection.autoconnect yes
# nmcli connection reload
# nmcli connection up eth0

# 192.168.122.113
hostnamectl set-hostname aws-n2.redhat.ren
# nmcli connection modify eth0 ipv4.method manual
# nmcli connection modify eth0 ipv4.dns 192.168.122.111
# nmcli connection modify eth0 connection.autoconnect yes
# nmcli connection reload
# nmcli connection up eth0

# 192.168.122.114
hostnamectl set-hostname aws-n3.redhat.ren
# nmcli connection modify eth0 ipv4.method manual
# nmcli connection modify eth0 ipv4.dns 192.168.122.111
# nmcli connection modify eth0 connection.autoconnect yes
# nmcli connection reload
# nmcli connection up eth0

# /dev/nvme1n1
ansible -i inventory aws -m service -a "name=dnsmasq state=restarted"
ansible -i inventory aws -m command -a "cat /etc/resolve.conf"
ansible -i inventory aws -m command -a "ls /etc/dnsmasq.d/"
ansible -i inventory aws -m copy -a "src=origin-upstream-dns.conf dest=/etc/dnsmasq.d/"
ansible -i inventory aws -m command -a "ping -c 1 aws-yum.redhat.ren"
ansible -i inventory aws -m command -a "rm -f /etc/NetworkManager/conf.d/disable-resolve.conf-managing.conf"

ansible -i inventory aws -m command -a "vgs"
```

## yum update

```bash

```


## 开始安装

```bash
ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/openshift-metrics/config.yml

# if uninstall, on each glusterfs nodes, run
vgremove -f $(vgs | tail -1 | awk '{print $1}')
pvremove $(pvs | tail -1 | awk '{print $1}')
# pvremove /dev/sdb2

crictl stopp $(crictl pods -q)
crictl rmp $(crictl pods -q)

htpasswd -cb /etc/origin/master/htpasswd admin  admin

oc adm policy add-cluster-role-to-user cluster-admin admin

oc adm policy remove-cluster-role-from-user cluster-admin admin

scp /etc/origin/master/htpasswd root@it-m2:/etc/origin/master/htpasswd
scp /etc/origin/master/htpasswd root@it-m3:/etc/origin/master/htpasswd
```

## cert redeploy

https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/configuring_clusters/install-config-certificate-customization#configuring-custom-certificates-retrofit

```bash

ansible-playbook -v -i hosts-3.11.98.yaml \
    /usr/share/ansible/openshift-ansible/playbooks/openshift-checks/certificate_expiry/easy-mode.yaml

# ansible-playbook -v -i hosts-3.11.98.yaml \
#     /usr/share/ansible/openshift-ansible/playbooks/openshift-master/redeploy-openshift-ca.yml --extra-vars "openshift_certificate_expiry_warning_days=5"

# ansible-playbook -v -i hosts-3.11.98.yaml \
#     /usr/share/ansible/openshift-ansible/playbooks/redeploy-certificates.yml



/bin/cp -f /root/down/cert/redhat.ren.fullchain1.pem  /etc/origin/master/named_certificates/redhat.ren.fullchain1.pem
/bin/cp -f /root/down/cert/redhat.ren.privkey1.pem /etc/origin/master/named_certificates/redhat.ren.privkey1.pem

scp /root/down/cert/redhat.ren.fullchain1.pem root@it-m2:/etc/origin/master/named_certificates/redhat.ren.fullchain1.pem
scp /root/down/cert/redhat.ren.privkey1.pem root@it-m2:/etc/origin/master/named_certificates/redhat.ren.privkey1.pem

scp /root/down/cert/redhat.ren.fullchain1.pem root@it-m3:/etc/origin/master/named_certificates/redhat.ren.fullchain1.pem
scp /root/down/cert/redhat.ren.privkey1.pem root@it-m3:/etc/origin/master/named_certificates/redhat.ren.privkey1.pem

ansible-playbook -v -i hosts-3.11.98.yaml \
    /usr/share/ansible/openshift-ansible/playbooks/redeploy-certificates.yml --extra-vars "openshift_certificate_expiry_warning_days=5"

ansible-playbook -v -i hosts-3.11.98.yaml \
    /usr/share/ansible/openshift-ansible/ansible-playbook playbooks/openshift-hosted/redeploy-router-certificates.yml --extra-vars "openshift_certificate_expiry_warning_days=5"

```

更新证书以后，grafana坏掉了 
https://access.redhat.com/solutions/3693251

```bash
oc delete secret -n openshift-monitoring  alertmanager-main-tls grafana-tls kube-state-metrics-tls node-exporter-tls prometheus-k8s-tls

oc get secrets -n openshift-monitoring | grep "\-tls"

oc delete pods -n openshift-monitoring --all

oc get pods -n openshift-monitoring 

```
