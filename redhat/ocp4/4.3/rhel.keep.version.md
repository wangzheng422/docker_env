# how to keep rhel version without upgrade 

https://avinetworks.com/docs/18.2/how-to-tie-a-system-to-a-specific-update/

```bash
head -n1 /etc/redhat-release | awk '{print $7}' > /etc/yum/vars/releasever


```