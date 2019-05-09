# 

## lftp

tar cvf ocp_3.11.98.tgz ocp_3.11.98/

split -b 100m ocp_3.11.98.tgz ocp.

lftp sftp://root:******@172.16.20.143

mirror -c -R --parallel=25 ./ /opt/litc/

split -b 50m rhel-server-7.6-x86_64-dvd.iso rhel.

mirror -c -R --parallel=40 ./ /opt/litc/