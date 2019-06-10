# 1 master 

## ansible

```bash
cd /home/ec2-user/down/inv/c2
# rm /home/ec2-user/.ssh/known_hosts
cat << EOF > ~/.ssh/config
StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config

ansible -i inventory aws -m ping
ansible -i inventory aws -m authorized_key -a "user=ec2-user key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDStcQmcsIt93Fkg8OVJabRXXqUQHtylMX0COkIS2hSk8JOVwXNjAX3199s1SIZ00179PwGcixXbQJs7FieBtu2JYb4XK4b37mbNfnls6+08Xc+3HCgEDaQf87bjnA4/ph3rriuipZWsbNw7mUg9GAsYTKZh3Bd9Y2WHD7eJ/AsqOKmox9ttNnR+g/z1RCMKUcvTHO29sPw/VmThdADQEfhhu4ErcYyFmy+G2hXY8fI2iYZdXrISc635eYs6DEHAtvKwxMV62/hm2gHYC3/u7ewDTntNd8tITCPr3KNRyNAHIGBDLN1xn2zw3o7tU2E/Bkw0iUmhC+YTToVOc9h42/T wzh@Wang-Zhengs-MacBook-Pro.local'"
ansible -i inventory aws -m timezone -a "name=Asia/Shanghai"
ansible -i inventory aws -m copy -a "src=chrony.conf dest=/etc/"
ansible -i inventory aws -m service -a "name=chronyd state=restarted"
ansible -i inventory aws -m command -a "chronyc tracking"
ansible -i inventory aws -m command -a "chronyc sources -v"
ansible -i inventory aws -m hostname -a "name={{ inventory_hostname }}"
ansible -i inventory aws -m command -a "hostnamectl"

ansible -i inventory aws -m command -a "mv -f /etc/yum.repos.d/ /etc/yum.repos.d.bak"
ansible -i inventory aws -m file -a "name=/etc/yum.repos.d state=directory"
ansible -i inventory aws -m command -a "ls /etc/yum.repos.d/"
ansible -i inventory aws -m yum_repository -a "name=ftp description=ftp baseurl=ftp://aws-yum.redhat.ren/yum gpgcheck=0"
ansible -i inventory aws -m command -a "yum clean all"
ansible -i inventory aws -m command -a "yum repolist"
ansible -i inventory aws -m yum -a "name=byobu,htop state=present"
ansible -i inventory aws -m yum -a "name=* state=latest"

ansible -i inventory aws -m command -a "reboot"

########################

ansible -i inventory aws -m ping

ansible -i inventory aws -m file -a "name=/etc/yum.repos.d.bak state=absent"
ansible -i inventory aws -m command -a "mv -f /etc/yum.repos.d/ /etc/yum.repos.d.bak"
ansible -i inventory aws -m file -a "name=/etc/yum.repos.d state=directory"
ansible -i inventory aws -m yum_repository -a "name=ftp description=ftp baseurl=ftp://aws-yum.redhat.ren/yum gpgcheck=0"
ansible -i inventory aws -m command -a "yum clean all"
ansible -i inventory aws -m command -a "yum repolist"

ansible -i inventory aws -m shell -a "df -h | head -n 5"
ansible -i inventory aws -m command -a "lsblk"

############################

ansible -i inventory aws[1:3] -m command -a "vgs"
ansible -i inventory aws[1:3] -m command -a "pvs"
ansible -i inventory aws[1:3] -m command -a "lsblk"
ansible -i inventory aws[1:3] -m shell -a "vgremove -f \$(vgs | tail -1 | awk '{print \$1}')"
ansible -i inventory aws[1:3] -m shell -a "pvremove \$(pvs | tail -1 | awk '{print \$1}')"

```

## 开始安装

```bash
ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/openshift-metrics/config.yml

ansible-playbook -v -i hosts-3.11.98.yaml /usr/share/ansible/openshift-ansible/playbooks/openshift-glusterfs/new_install.yml

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
