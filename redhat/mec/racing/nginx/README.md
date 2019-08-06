#

https://github.com/nginxinc/kubernetes-ingress

https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md

https://github.com/nginxinc/nginx-openshift-router/tree/master/examples/tcp-udp

```bash
oc apply -f common/ns-and-sa.yaml
oc apply -f common/default-server-secret.yaml
oc apply -f common/nginx-config.yaml
oc apply -f common/custom-resource-definitions.yaml

oc apply -f rbac/rbac.yaml

oc adm policy add-scc-to-user privileged -n nginx-ingress -z nginx-ingress

oc apply -f daemon-set/nginx-ingress.yaml


oc delete -f daemon-set/nginx-ingress.yaml
```