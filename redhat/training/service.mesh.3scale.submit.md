URL for lab:
https://console-openshift-console.apps.cluster-5064.5064.sandbox1845.opentlc.com/k8s/ns/bookretail-istio-system/pods

username: admin
password: r3dh4t1!

```bash
###################################################
## shell script for Automation script 

echo "apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
  # a list of projects joined into the service mesh
  - bookinfo
" > $HOME/service-mesh-roll.yaml

oc apply -f $HOME/service-mesh-roll.yaml -n bookretail-istio-system

oc get deploy -n bookinfo -o json > test
cat test | jq -r .items[].metadata.name | xargs -I DEMO oc patch deploy DEMO -p '{"spec":{"template": { "metadata" : { "annotations" : {  "sidecar.istio.io/inject": "true" } }   } }}'

## end of script
########################################################
```