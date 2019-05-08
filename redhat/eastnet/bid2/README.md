# 

## lftp

tar cvf ocp_3.11.98.tgz ocp_3.11.98

split -b 500m ocp_3.11.98.tgz ocp.

lftp sftp://root:******@172.16.20.143

mirror -R --parallel=22 ./ /opt/litc/