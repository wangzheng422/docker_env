```bash
ssh -i ~/.ssh/id_rsa.redhat -tt zhengwan-redhat.com@bastion.94a2.sandbox1776.opentlc.com byobu

sudo -i

mkdir -p ${HOME}/cluster-${GUID}
sudo cp -R /home/ec2-user/cluster-${GUID}/auth $HOME/cluster-${GUID}
sudo chown -R $(whoami):users $HOME/cluster-$GUID

export KUBECONFIG=${HOME}/cluster-${GUID}/auth/kubeconfig
echo "export KUBECONFIG=${HOME}/cluster-${GUID}/auth/kubeconfig" >>$HOME/.bashrc

oc login -u user1 -p r3dh4t1!

oc login -u system:admin

# http://console-openshift-console.apps.cluster-94a2.94a2.sandbox1776.opentlc.com

echo -en "\n\nhttps://`oc get route console -o template --template {{.spec.host}} -n openshift-console`\n"

oc get ClusterServiceVersion
oc get pod  -n openshift-operators | grep "^elasticsearch"

oc get ClusterServiceVersion
oc get pod  -n openshift-operators | grep "^jaeger"

oc get ClusterServiceVersion
oc get pod  -n openshift-operators | grep "^kiali"

oc adm new-project istio-operator --display-name="Service Mesh Operator"
oc project istio-operator

oc apply -n istio-operator -f https://raw.githubusercontent.com/Maistra/istio-operator/maistra-1.0.0/deploy/servicemesh-operator.yaml

oc get pod -n istio-operator

oc logs -n istio-operator $(oc -n istio-operator get pods -l name=istio-operator --output=jsonpath={.items..metadata.name})

oc adm new-project istio-system --display-name="Service Mesh System"

echo "apiVersion: maistra.io/v1
kind: ServiceMeshControlPlane
metadata:
  name: service-mesh-installation
spec:
  threeScale:
    enabled: false

  istio:
    global:
      mtls: false
      disablePolicyChecks: false
      proxy:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 128Mi

    gateways:
      istio-egressgateway:
        autoscaleEnabled: false
      istio-ingressgateway:
        autoscaleEnabled: false
        ior_enabled: false

    mixer:
      policy:
        autoscaleEnabled: false

      telemetry:
        autoscaleEnabled: false
        resources:
          requests:
            cpu: 100m
            memory: 1G
          limits:
            cpu: 500m
            memory: 4G

    pilot:
      autoscaleEnabled: false
      traceSampling: 100.0

    kiali:
      dashboard:
        user: admin
        passphrase: redhat
    tracing:
      enabled: true

" > $HOME/service-mesh.yaml

oc apply -f $HOME/service-mesh.yaml -n istio-system

watch oc get pods -n istio-system
# NAME                                      READY   STATUS    RESTARTS   AGE
# grafana-7c9b49897-vnfb7                   2/2     Running   0          9m22s
# istio-citadel-7cdf78f8d7-98llq            1/1     Running   0          16m
# istio-egressgateway-757d97cc65-mm2b7      1/1     Running   0          10m
# istio-galley-59fd5df664-kktrk             1/1     Running   0          14m
# istio-ingressgateway-79cf488c9b-85cgh     1/1     Running   0          10m
# istio-pilot-6559576c98-2z762              2/2     Running   0          11m
# istio-policy-56d996cb65-2kdh9             2/2     Running   0          13m
# istio-sidecar-injector-576b857596-k9jbt   1/1     Running   0          10m
# istio-telemetry-cc6586bfc-cl66p           2/2     Running   0          13m
# jaeger-65f55f7bc6-849z9                   2/2     Running   0          14m
# kiali-f9779f7f9-mnjbx                     1/1     Running   0          6m12s
# prometheus-77c95d7588-wp4jj               2/2     Running   0          15m

oc get route kiali -n istio-system -o jsonpath='{"https://"}{.spec.host}{"\n"}'
# https://kiali-istio-system.apps.cluster-94a2.94a2.sandbox1776.opentlc.com

echo "apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
  # a list of projects joined into the service mesh
  - user1-tutorial
" > $HOME/service-mesh-roll.yaml

oc login -u user1 -p r3dh4t1!

echo "export OCP_TUTORIAL_PROJECT=user1-tutorial" >> $HOME/.bashrc
source $HOME/.bashrc

oc new-project $OCP_TUTORIAL_PROJECT

mkdir ~/lab && cd "$_"

git clone https://github.com/gpe-mw-training/ocp-service-mesh-foundations

cd ocp-service-mesh-foundations

cd ~/lab/ocp-service-mesh-foundations/catalog

oc create \
     -f kubernetes/catalog-service-template.yml \
     -n $OCP_TUTORIAL_PROJECT

oc create \
     -f ~/lab/ocp-service-mesh-foundations/catalog/kubernetes/Service.yml \
     -n $OCP_TUTORIAL_PROJECT

cd ~/lab/ocp-service-mesh-foundations/partner

oc create \
     -f kubernetes/partner-service-template.yml \
     -n $OCP_TUTORIAL_PROJECT

oc create \
     -f ~/lab/ocp-service-mesh-foundations/partner/kubernetes/Service.yml \
     -n $OCP_TUTORIAL_PROJECT

cd ~/lab/ocp-service-mesh-foundations/gateway

oc create \
     -f kubernetes/gateway-service-template.yml \
     -n $OCP_TUTORIAL_PROJECT

oc create \
     -f ~/lab/ocp-service-mesh-foundations/gateway/kubernetes/Service.yml \
     -n $OCP_TUTORIAL_PROJECT

echo -en "apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ingress-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - '*'
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ingress-gateway
spec:
  hosts:
  - '*'
  gateways:
  - ingress-gateway
  http:
  - match:
    - uri:
        exact: /
    route:
    - destination:
        host: gateway
        port:
          number: 8080
" > $HOME/service-mesh-gw.yaml

oc apply -f $HOME/service-mesh-gw.yaml -n $OCP_TUTORIAL_PROJECT

echo "export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')" >> ~/.bashrc

source ~/.bashrc

echo $GATEWAY_URL

curl $GATEWAY_URL

oc create \
     -f ~/lab/ocp-service-mesh-foundations/catalog-v2/kubernetes/catalog-service-template.yml \
     -n $OCP_TUTORIAL_PROJECT

oc get pods -l application=catalog -n $OCP_TUTORIAL_PROJECT -w

oc describe service catalog -n $OCP_TUTORIAL_PROJECT | grep Selector

oc get deploy catalog-v1 -o json -n $OCP_TUTORIAL_PROJECT | jq .spec.template.metadata.labels

oc get deploy catalog-v2 -o json -n $OCP_TUTORIAL_PROJECT | jq .spec.template.metadata.labels

oc create -f ~/lab/ocp-service-mesh-foundations/istiofiles/destination-rule-catalog-v1-v2.yml -n $OCP_TUTORIAL_PROJECT

oc create -f ~/lab/ocp-service-mesh-foundations/istiofiles/virtual-service-catalog-v2.yml -n $OCP_TUTORIAL_PROJECT

oc replace -f ~/lab/ocp-service-mesh-foundations/istiofiles/virtual-service-catalog-v1.yml -n $OCP_TUTORIAL_PROJECT

export KIALI_URL=https://$(oc get route kiali -n istio-system -o template --template='{{.spec.host}}')
echo $KIALI_URL

cd ~/lab/ocp-service-mesh-foundations
$HOME/lab/ocp-service-mesh-foundations/scripts/run-all.sh

```

service mesh install and uninstall
```
oc get MutatingWebhookConfiguration
oc get ValidatingWebhookConfiguration
oc delete ValidatingWebhookConfiguration istio-system.servicemesh-resources.maistra.io
oc delete ValidatingWebhookConfiguration openshift-operators.servicemesh-resources.maistra.io
oc get ValidatingWebhookConfiguration
```