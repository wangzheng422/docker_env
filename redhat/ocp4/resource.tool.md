```bash
wget --no-check-certificate https://downloads-openshift-console.apps.shared.na.openshift.opentlc.com/amd64/linux/oc
sudo mv oc /usr/local/bin/oc
sudo chmod a+x /usr/local/bin/oc

oc login -u zhengwan-redhat.com https://api.shared.na.openshift.opentlc.com:6443
oc version --short
oc whoami --show-server
oc whoami --show-token
oc whoami --show-context

cat $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/new-config
oc login -u panni-redhat.com 

oc api-versions
oc api-resources 
oc explain pod --recursive 

export EDITOR=/usr/bin/vim 

oc new-project $GUID-openshift-tools --display-name="OpenShift Tools"
oc project
oc new-app cakephp-mysql-example
oc status
oc logs -f pod/cakephp-mysql-example-1-deploy
oc get pods --field-selector status.phase=Running

oc get appliedclusterresourcequotas
oc describe appliedclusterresourcequota clusterquota-zhengwan-redhat.com-67d9
oc get pods --field-selector=status.phase=Running -o json | jq '.items[] | {name: .metadata.name, res: .spec.containers[].resources}'
oc set resources dc cakephp-mysql-example --limits=memory=1Gi

oc explain deployment --api-version=apps/v1beta2
oc explain deployment.metadata.name --api-version=apps/v1

oc rollout status deployment ocp-probe
oc scale deployment ocp-probe --replicas=3

oc new-app --docker-image=quay.io/gpte-devops-automation/ocp-probe:v0.4 --name=green
oc expose svc green --name=bluegreen
export ROUTE=$(oc get route bluegreen -o jsonpath='{.spec.host}')
oc new-app --docker-image=quay.io/gpte-devops-automation/ocp-probe:v0.5 --name=blue
oc edit route bluegreen
oc patch route/bluegreen -p '{"spec":{"to":{"name":"green"}}}'
#   alternateBackends:
#   - kind: Service
#     name: blue
#     weight: 50
oc set route-backends bluegreen blue=9 green=1
while true; do curl $ROUTE/version ; echo ""; sleep 1; done
```