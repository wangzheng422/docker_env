# how to keep rhel version without upgrade 

https://avinetworks.com/docs/18.2/how-to-tie-a-system-to-a-specific-update/

```bash
head -n1 /etc/redhat-release | awk '{print $7}' > /etc/yum/vars/releasever

# Modify the /etc/yum.conf file under the [main] heading:
# [main] distroverpkg=7.6

# prepare the offline repo
subscription-manager release --list

subscription-manager release --set=7.6

yum clean all

subscription-manager release --show

```

others
```bash
rm /etc/yum/vars/releasever

# Get all yum commands previously run
yum history list all

# Get the details of the command
yum history info [entry number]

# Undo each command top-down
yum history undo [entry number]

```