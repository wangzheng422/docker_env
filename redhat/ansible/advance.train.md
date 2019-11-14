awx is opensource version of ansible tower

https://github.com/ansible/awx

```bash

# https://docs.adfinis-sygroup.ch/public/ansible-guide/

# show groups
ansible-inventory -i inventory --graph

ansible-playbook **.yml --limit 'web'    

# d([]) iterm.split   lstrip


ssh -i ~/.ssh/id_rsa.redhat -tt zhengwan-redhat.com@bastion.3a84.example.opentlc.com byobu

export GUID=3a84
export MYKEY=~/.ssh/sborenstkey
export MYUSER=zhengwan-redhat.com

ssh -i ${MYKEY} ${MYUSER}@bastion.${GUID}.example.opentlc.com

###########################
## 3 tier
ssh -i ~/.ssh/id_rsa.redhat -tt zhengwan-redhat.com@bastion.3a84.example.opentlc.com byobu

ansible all --list-hosts

export GUID=`hostname | awk -F"." '{print $2}'`
echo ${GUID}

ssh app1.${GUID}.internal

ssh -i ~/.ssh/3a84key.pem ec2-user@appdb1.${GUID}.internal

export GUID=`hostname | awk -F"." '{print $2}'`
mkdir ~/.ssh
sudo cp /root/.ssh/${GUID}key.pem ~/.ssh
sudo chown `whoami` ~/.ssh/${GUID}key.pem
sudo chmod 400 ~/.ssh/${GUID}key.pem
cp /etc/ansible/hosts ~/myinventory.file

git clone https://github.com/wangzheng422/bad-ansible
cp /etc/yum.repos.d/open_three-tier-app.repo bad-ansible/

ansible-playbook main.yml  -e "GUID=${GUID}"
ansible-playbook cleanup.yml  -e "GUID=${GUID}"

# https://github.com/prakhar1985/good-ansible

wget http://www.opentlc.com/download/ansible_bootcamp/openstack_keys/openstack.pub
cat openstack.pub  >> /home/ec2-user/.ssh/authorized_keys

cat ~/.ssh/3a84key.pem

curl http://frontend1.${GUID}.example.opentlc.com/

###########################3
## tower
ssh -i ~/.ssh/id_rsa.redhat -tt zhengwan-redhat.com@bastion.2b40.example.opentlc.com byobu

mkhomedir_helper zhengwan-redhat.com

export GUID=`hostname | awk -F"." '{print $2}'`
echo $GUID

echo https://tower2.${GUID}.example.opentlc.com/

ansible localhost -m unarchive -a "src=https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz dest=/root/ remote_src=yes"

cat << EOF > /root/ansible-tower-setup-*/inventory
[tower]
tower1.${GUID}.internal
tower2.${GUID}.internal
tower3.${GUID}.internal
[database]
support1.${GUID}.internal
[all:vars]
ansible_become=true
admin_password='r3dh4t1!'

pg_host='support1.${GUID}.internal'
pg_port='5432'

pg_database='awx'
pg_username='awx'
pg_password='r3dh4t1!'

rabbitmq_port=5672
rabbitmq_vhost=tower

rabbitmq_username=tower
rabbitmq_password='redhat'
rabbitmq_cookie=cookiemonster

rabbitmq_use_long_name=true
EOF

export APP_GUID=3a84
ansible all -i bastion.${APP_GUID}.example.opentlc.com, --private-key=~/.ssh/openstack.pem -u ec2-user -m ping


cat << EOF > /root/ansible-tower-setup-*/inventory
[tower]
tower1.${GUID}.internal
tower2.${GUID}.internal
tower3.${GUID}.internal

[database]
support1.${GUID}.internal

[isolated_group_ThreeTierApp]
bastion.3a84.example.opentlc.com ansible_user='ec2-user' ansible_ssh_private_key_file='~/.ssh/openstack.pem'

[isolated_group_ThreeTierApp:vars]
controller=tower

[all:vars]
ansible_become=true
admin_password='r3dh4t1!'
pg_host='support1.${GUID}.internal'
pg_port='5432'
pg_database='awx'
pg_username='awx'
pg_password='r3dh4t1!'
rabbitmq_port=5672
rabbitmq_vhost=tower
rabbitmq_username=tower
rabbitmq_password='redhat'
rabbitmq_cookie=cookiemonster
rabbitmq_use_long_name=true
EOF

pip install pywinrm
ansible windows -m win_ping
mkdir -p roles/win_ad_install/{tasks,defaults}

yum -y install python-devel krb5-devel krb5-libs krb5-workstation python-pip gcc
pip install "pywinrm>=0.2.2"
pip install pywinrm[kerberos]

export GUID=`hostname | awk -F"." '{print $2}'`
export GUID_CAP=`echo ${GUID} | tr 'a-z' 'A-Z'`

mkdir -p roles/win_ad_install/{tasks,defaults}
cat << EOF > roles/win_ad_install/tasks/main.yml
- name: Install AD-Domain-Services feature
  win_feature:
    name: AD-Domain-Services
    include_management_tools: yes
    include_sub_features: yes

- name: Setup Active Directory Controller
  win_domain:
    dns_domain_name: "{{ ad_domain_name }}"
    safe_mode_password: "{{ ad_safe_mode_password }}"
  register: active_directory_controllers

- name: Reboot once DC created
  win_reboot:
  when: active_directory_controllers.reboot_required

- name: List Domain Controllers in domain
  win_shell: "nltest /dclist:{{ ad_domain_name }}"
  register: domain_list

- debug:
   var: domain_list
EOF

cat << EOF > roles/win_ad_install/defaults/main.yml
ad_domain_name: ad1.${GUID}.example.opentlc.com
ad_safe_mode_password: "{{ansible_password}}"
ad_admin_user: "admin@{{ ad_domain_name}}"
ad_admin_password: "{{ansible_password}}"
EOF


cat << EOF > setup_ad.yml
---
- name: install and configure active directory
  hosts: windows
  gather_facts: false

  roles:
    - win_ad_install
EOF

cat << EOF > /etc/krb5.conf.d/ansible.conf

[realms]

 AD1.${GUID_CAP}.EXAMPLE.OPENTLC.COM = {

 kdc = ad1.${GUID}.example.opentlc.com
 }

[domain_realm]
 .ad1.${GUID}.example.opentlc.com = AD1.${GUID_CAP}.EXAMPLE.OPENTLC.COM
EOF

mkdir -p roles/win_service_config/{tasks,vars}

cat << EOF > roles/win_service_config/tasks/main.yml
---
- name: Install Windows package
  win_chocolatey:
    name: "{{ package_name }}"
    params: "{{ parameters }}"
    state: latest
  when: ansible_distribution == "Microsoft Windows Server 2012 R2 Standard"

- name: Start windows service
  win_service:
    name: "{{ service_name }}"
    state: started
    start_mode: auto
  when: ansible_distribution == "Microsoft Windows Server 2012 R2 Standard"

- name: Add win_firewall_rule
  win_firewall_rule:
    name: "{{ service_name }}"
    localport: "{{ local_port }}"
    action: allow
    direction: in
    protocol: "{{ protocol_name }}"
    state: present
    enabled: yes
EOF

cat << EOF > ssh_var.yml
package_name: openssh
parameters: /SSHServerFeature
service_name: SSHD
local_port: 22
protocol_name: tcp
EOF

cat << EOF > win_ssh_server.yml
- hosts: windows
  vars_files:
    - ./ssh_var.yml
  roles:
    - win_service_config
EOF


cat << EOF > ad_user_vars.yml
# vars file for roles/win_ad_user
user_info:
  - { name: 'james', firstname: 'James', surname: 'Jockey', password: 'redhat@123', group_name: 'dev', group_scope: 'domainlocal'}
  - { name: 'bill', firstname: 'Bill', surname: 'Gates', password: 'redhat@123', group_name: 'dev', group_scope: 'domainlocal'}
  - { name: 'mickey', firstname: 'Mickey', surname: 'Mouse', password: 'redhat@123', group_name: 'qa', group_scope: 'domainlocal'}
  - { name: 'donald', firstname: 'Donald', surname: 'Duck', password: 'redhat@123', group_name: 'qa', group_scope: 'domainlocal'}
EOF

export GUID=`hostname | awk -F"." '{print $2}'`
mkdir -p roles/win_ad_user/{tasks,vars}
cat << EOF > roles/win_ad_user/tasks/main.yml
---
# tasks file for roles/win_ad_user
- name: Create windows domain group
  win_domain_group:
    name: "{{ item.group_name }}"
    scope: "{{ item.group_scope }}"
    state: present
  loop: "{{ user_info }}"

- name: Create AD User
  win_domain_user:
    name: "{{ item.name }}"
    firstname: "{{item.firstname }}"
    surname: "{{ item.surname }}"
    password: "{{ item.password }}"
    groups: "{{ item.group_name }}"
    state: present
    email: '"{{ item.name }}"@ad1.${GUID}.example.opentlc.com'
  loop: "{{ user_info }}"
EOF

kinit mickey@AD1.${GUID_CAP}.EXAMPLE.OPENTLC.COM

klist


ansible support1.${GUID}.internal -m lineinfile -a "line='include_dir = 'conf.d'' path=/var/lib/pgsql/9.6/data/postgresql.conf"

ansible support1.${GUID}.internal -m file -a 'path=/var/lib/pgsql/9.6/data/conf.d state=directory'

cat << EOF > tower-postgresql.conf
wal_level = hot_standby
synchronous_commit = local
archive_mode = on
archive_command = 'cp %p /var/lib/pgsql/9.6/data/archive/%f'
max_wal_senders = 2
wal_keep_segments = 10
synchronous_standby_names = 'slave01'
EOF

ansible support1.${GUID}.internal -m lineinfile -a "line='hot_standby = on' path=/var/lib/pgsql/9.6/data/postgresql.conf"

ansible support1.${GUID}.internal -m copy -a "src=/root/tower-postgresql.conf dest=/var/lib/pgsql/9.6/data/conf.d/tower-postgresql.conf"

ansible support1.${GUID}.internal -m service -a"name=postgresql-9.6 state=restarted"

ansible support1.${GUID}.internal -m postgresql_user -a "name=replica password=r3dh4t1! role_attr_flags=REPLICATION state=present" --become-user=postgres

ansible support2.${GUID}.internal -m get_url -a "url=http://www.opentlc.com/download/ansible_bootcamp/repo/pgdg-96-centos.repo dest=/etc/yum.repos.d/pgdg-96-centos.repo"

ansible support2.${GUID}.internal -m get_url -a "url=http://www.opentlc.com/download/ansible_bootcamp/repo/RPM-GPG-KEY-PGDG-96 dest=/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-96"

ansible support2.${GUID}.internal -m yum -a "name=postgresql96-server state=present"

ansible support1.${GUID}.internal -m lineinfile -a "line='hot_standby = on' path=/var/lib/pgsql/9.6/data/postgresql.conf state=absent" 

ansible support1.${GUID}.internal  -m lineinfile -a "line='host    replication replica     0.0.0.0/0        md5' path=/var/lib/pgsql/9.6/data/pg_hba.conf"

ansible support2.${GUID}.internal -m service -a"name=postgresql-9.6 state=stopped"

ansible support2.${GUID}.internal -m lineinfile -a "line='hot_standby = on' path=/var/lib/pgsql/9.6/data/postgresql.conf"

ansible support2.${GUID}.internal -m shell -a "export PGPASSWORD=r3dh4t1! && pg_basebackup -h support1.${GUID}.internal -U replica -D /var/lib/pgsql/9.6/data/ -P --xlog" --become-user=postgres

ansible support2.${GUID}.internal -m lineinfile -a "line='hot_standby = on' path=/var/lib/pgsql/9.6/data/postgresql.conf"

cat << EOF > recovery.conf
restore_command = 'scp support1.${GUID}.internal:/var/lib/pgsql/9.6/data/archive/%f %p'
standby_mode = on
primary_conninfo = 'host=support1.${GUID}.internal port=5432 user=replica password=r3dh4t1! application_name=slave01'
EOF

ansible support2.${GUID}.internal -m copy -a "src=/root/recovery.conf dest=/var/lib/pgsql/9.6/data/recovery.conf"

ansible support2.${GUID}.internal -m service -a "name=postgresql-9.6 state=started enabled=true"

ansible-galaxy install samdoran.pgsql_replication -p roles

vim roles/samdoran.pgsql_replication/tasks/master.yml
# loop: "{{ pgsqlrep_replica_address }}"
# vars:
#   pgsqlrep_replica_address: "{{ groups[pgsqlrep_group_name] | map('extract', hostvars, 'ansible_all_ipv4_addresses') | flatten }}"
# notify: restart postgresql

cat << EOF > pg_inventory
[tower]
tower1.2b40.internal public_host_name=tower1.2b40.example.opentlc.com ssh_host=tower2.2b40.internal
tower2.2b40.internal public_host_name=tower2.2b40.example.opentlc.com ssh_host=tower1.2b40.internal
tower3.2b40.internal public_host_name=tower3.2b40.example.opentlc.com ssh_host=tower3.2b40.internal

[database]
support1.2b40.internal ssh_host=support2.2b40.internal  pgsqlrep_role=master

[database_replica]
support2.${GUID}.internal pgsqlrep_role=replica

[isolated_group_ThreeTierApp]
bastion.3a84.example.opentlc.com ansible_user='ec2-user' ansible_ssh_private_key_file='~/.ssh/openstack.pem'

[isolated_group_ThreeTierApp:vars]
controller=tower

[all:vars]
ansible_become=true
admin_password='root'

pg_host='support1.2b40.internal'
pg_port='5432'

pg_database='awx'
pg_username='awx'
pg_password='root'

rabbitmq_vhost=tower
rabbitmq_use_long_name=true

rabbitmq_username=tower
rabbitmq_password='root'
rabbitmq_cookie=cookiemonster

# Isolated Tower nodes automatically generate an RSA key for authentication;
# To disable this behavior, set this value to false
# isolated_key_generation=true
EOF

cat << EOF > pgsql_replication.yml
- name: Configure PostgreSQL streaming replication
  hosts: database_replica

  tasks:
    - name: Find recovery.conf
      find:
        paths: /var/lib/pgsql
        recurse: yes
        patterns: recovery.conf
      register: recovery_conf_path

    - name: Remove recovery.conf
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ recovery_conf_path.files }}"

    - name: Add replica to database group
      add_host:
        name: "{{ inventory_hostname }}"
        groups: database
      tags:
        - always

    - import_role:
        name: nginx
      vars:
        nginx_exec_vars_only: yes

    - import_role:
        name: repos_el
      when: ansible_os_family == "RedHat"

    - import_role:
        name: packages_el
      vars:
        packages_el_install_tower: no
        packages_el_install_postgres: yes
      when: ansible_os_family == "RedHat"

    - debug:
        msg: "postgres_username: {{ pg_username }}"
    
    - debug:
        msg: "postgres_password: {{ pg_password }}"

    - import_role:
        name: postgres
      vars:
        postgres_allowed_ipv4: "0.0.0.0/0"
        postgres_allowed_ipv6: "::/0"
        postgres_username: "{{ pg_username }}"
        postgres_password: "{{ pg_password }}"
        postgres_database: "{{ pg_database }}"
        max_postgres_connections: 1024
        postgres_shared_memory_size: "{{ (ansible_memtotal_mb*0.3)|int }}"
        postgres_work_mem: "{{ (ansible_memtotal_mb*0.03)|int }}"
        postgres_maintenance_work_mem: "{{ (ansible_memtotal_mb*0.04)|int }}"
      tags:
        - postgresql_database

    - import_role:
        name: firewall
      vars:
        firewalld_http_port: "{{ nginx_http_port }}"
        firewalld_https_port: "{{ nginx_https_port }}"
      tags:
        - firewall
      when: ansible_os_family == 'RedHat'

- name: Configure PSQL master server
  hosts: database[0]

  vars:
    pgsqlrep_master_address: "{{ hostvars[groups[pgsqlrep_group_name_master][0]].ansible_all_ipv4_addresses[-1] }}"
    pgsqlrep_replica_address: "{{ hostvars[groups[pgsqlrep_group_name][0]].ansible_all_ipv4_addresses[-1] }}"

  tasks:
    - import_role:
        name: samdoran.pgsql_replication

- name: Configure PSQL replica
  hosts: database_replica

  vars:
    pgsqlrep_master_address: "{{ hostvars[groups[pgsqlrep_group_name_master][0]].ansible_all_ipv4_addresses[-1] }}"
    pgsqlrep_replica_address: "{{ hostvars[groups[pgsqlrep_group_name][0]].ansible_all_ipv4_addresses[-1] }}"

  tasks:
    - import_role:
        name: samdoran.pgsql_replication
EOF

ansible-playbook -b -i pg_inventory pgsql_replication.yml -e pgsqlrep_password=r3dh4t1!

ansible support1.${GUID}.internal -m shell -a "psql -c 'select application_name, state, sync_priority, sync_state from pg_stat_replication;'" --become-user postgres

cat << EOF > postgres_failover.yml
- name: Gather facts
  hosts: all
  become: yes

- name: Failover PostgreSQL
  hosts: database_replica
  become: yes

  tasks:
    - name: Get the current PostgreSQL Version
      import_role:
        name: samdoran.pgsql_replication
        tasks_from: pgsql_version.yml

    - name: Promote secondary PostgreSQL server to primary
      command: /usr/pgsql-{{ pgsql_version }}/bin/pg_ctl promote
      become_user: postgres
      environment:
        PGDATA: /var/lib/pgsql/{{ pgsql_version }}/data
      ignore_errors: yes

- name: Update Ansible Tower database configuration
  hosts: tower
  become: yes

  tasks:
    - name: Update Tower postgres.py
      lineinfile:
        dest: /etc/tower/conf.d/postgres.py
        regexp: "^(.*'HOST':)"
        line: "\\\\1 '{{ hostvars[groups['database_replica'][0]].ansible_default_ipv4.address }}',"
        backrefs: yes
      notify: restart tower

  handlers:
    - name: restart tower
      command: ansible-tower-service restart
EOF

ansible-playbook -b -i pg_inventory postgres_failover.yml -e pgsqlrep_password=r3dh4t1!

```

```
myapp/
├── config.yml
├── provision.yml
├── roles
│   └── requirements.yml
└── setup.yml

$ ansible-galaxy install -r requirements.yml

$ cat requirements.yml

# from galaxy
- src: yatesr.timezone

# from GitHub
- src: https://github.com/bennojoy/nginx
  version: v1.4

# from a webserver, where the role is packaged in a tar.gz
- src: https://some.webserver.example.com/files/master.tar.gz
  name: http-role


###################
- name: check for proper response
  uri:
    url: http://localhost/myapp
    return_content: yes
  register: result
  until: '"Hello World" in result.content'
  retries: 10
  delay: 1

#####################
[windows]
## These are the windows servers
ad1.${GUID}.internal ssh_host=${PUBLIC_ACCESSIBLE_HOSTNAME} ansible_password=${ADMINISTRATOR_PASWORD}

[windows:vars]
ansible_connection=winrm
ansible_user=Administrator
ansible_winrm_server_cert_validation=ignore
ansible_become=false

###################
- name: Install AD-Domain-Services feature
  win_feature:
    name: AD-Domain-Services
    include_management_tools: yes
    include_sub_features: yes

- name: Setup Active Directory Controller
  win_domain:
    dns_domain_name: "{{ ad_domain_name }}"
    safe_mode_password: "{{ ad_safe_mode_password }}"
  register: active_directory_controllers

- name: Reboot once DC created
  win_reboot:
  when: active_directory_controllers.reboot_required

- name: List Domain Controllers in domain
  win_shell: "nltest /dclist:{{ ad_domain_name }}"
  register: domain_list

- debug:
   var: domain_list


#######################################
###   pgsql_replication.yml



```