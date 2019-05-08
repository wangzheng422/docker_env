#

https://docs.openshift.com/container-platform/3.11/servicemesh-install/servicemesh-install.html

```bash
oc create -n istio-system -f istio-installation.yaml

oc apply -n istio-system -f istio-installation.yaml

oc get pods -n istio-system -w

oc get controlplane/basic-install -n istio-system --template='{{range .status.conditions}}{{printf "%s=%s, reason=%s, message=%s\n\n" .type .status .reason .message}}{{end}}'

# delete
oc get controlplanes -n istio-system
oc delete -n istio-system -f istio-installation.yaml

oc delete -n istio-operator -f https://raw.githubusercontent.com/Maistra/istio-operator/maistra-0.10/deploy/servicemesh-operator.yaml

# apply patch 
cd /etc/origin/master/

cp -p master-config.yaml master-config.yaml.prepatch
oc ex config patch master-config.yaml.prepatch -p "$(cat master-config.patch)" > master-config.yaml
/usr/local/bin/master-restart api && /usr/local/bin/master-restart controllers

# demo

oc new-project myproject

oc adm policy add-scc-to-user anyuid -z default -n myproject
oc adm policy add-scc-to-user privileged -z default -n myproject

oc apply -n myproject -f https://raw.githubusercontent.com/Maistra/bookinfo/master/bookinfo.yaml

oc apply -n myproject -f https://raw.githubusercontent.com/Maistra/bookinfo/master/bookinfo-gateway.yaml

export GATEWAY_URL=$(oc get route -n istio-system istio-ingressgateway -o jsonpath='{.spec.host}')

echo http://$GATEWAY_URL/productpage

oc apply -n myproject -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/networking/destination-rule-all.yaml

export JAEGER_URL=$(oc get route -n istio-system jaeger-query -o jsonpath='{.spec.host}')

echo https://${JAEGER_URL}

oc get svc prometheus -n istio-system

export PROMETHEUS_URL=$(oc get route -n istio-system prometheus -o jsonpath='{.spec.host}')

echo http://${PROMETHEUS_URL}

oc get prometheus -n istio-system -o jsonpath='{.items[*].spec.metrics[*].name}' requests_total request_duration_seconds request_bytes response_bytes tcp_sent_bytes_total tcp_received_bytes_total

oc project istio-system
oc get routes

export GRAFANA_URL=$(oc get route -n istio-system grafana -o jsonpath='{.spec.host}')

echo http://${GRAFANA_URL}

```