#

eap 10.147.17.80

```bash
./standalone.sh -Djboss.bind.address=10.147.17.80 -Djboss.bind.address.management=10.147.17.80

firewall-cmd --get-zone-of-interface=ztnfaahj5u
firewall-cmd --permanent --new-zone=zerotier
firewall-cmd --permanent --delete-zone=zerotier

firewall-cmd --list-all-zones

firewall-cmd --permanent --zone=home --add-interface=ztnfaahj5u
firewall-cmd --zone=home --add-port=8080/tcp --permanent
firewall-cmd --zone=home --add-port=8443/tcp --permanent
firewall-cmd --zone=home --add-port=9990/tcp --permanent
firewall-cmd --reload

firewall-cmd --list-all

./add-user.sh -u 'admin' -p 'admin' -g 'guest,mgmtgroup'


./target/jboss-eap-7.2/bin/standalone.sh -b 10.147.17.36
```

https://github.com/jbossdemocentral/rhpam7-install-demo

docker run -it -p 8080:8080 -p 9990:9990 jbossdemocentral/rhpam7-install-demo

Login into Business Central at:

http://v2.wandering.wang:8080/business-central  (u:pamAdmin / p:redhatpam1!)       

Login into Case Management Showcase Application at:                        

http://v2.wandering.wang:8080/rhpam-case-mgmt-showcase  (u:pamAdmin / p:redhatpam1!)