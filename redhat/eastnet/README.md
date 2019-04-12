#

<https://github.com/Maistra/openshift-ansible/blob/maistra-0.9/istio/Installation.md>

```bash
# ansible prepare for istio
copy src=./99-elasticsearch.conf dest=/etc/sysctl.d/
shell sysctl vm.max_map_count=262144

# install istio
cd /etc/origin/master
cp -p master-config.yaml master-config.yaml.prepatch
oc ex config patch master-config.yaml.prepatch -p "$(cat master-config.patch)" > master-config.yaml
/usr/local/bin/master-restart api && /usr/local/bin/master-restart controllers


oc new-project istio-operator
oc new-app -f istio_product_operator_template.yaml --param=OPENSHIFT_ISTIO_MASTER_PUBLIC_URL=https://console.paas.com:7443

 oc get cm -n istio-system istio -o jsonpath='{.data.mesh}' | grep disablePolicyChecks

 oc process -f istio_product_operator_template.yaml | oc delete -f -
```