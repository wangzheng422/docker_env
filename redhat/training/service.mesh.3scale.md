```bash
ssh -tt root@bastion.1b26.example.opentlc.com 'bash -l -c byobu'

yum install openssl jq

wget https://github.com/istio/istio/releases/download/1.3.5/istio-1.3.5-linux.tar.gz

install istioctl /usr/local/bin

mkdir -p $HOME/lab

curl https://raw.githubusercontent.com/honghuac/ocp_service_mesh_advanced-1/master/utils/set_env_vars.sh -o $HOME/lab/set_env_vars.sh && chmod 775 $HOME/lab/set_env_vars.sh


# ######     CHANGE THE VALUES IN THIS SECTION !!!!!!    ################
echo "export ERD_ID=8" >> $HOME/.bashrc
echo "export LAB_ID=8" >> $HOME/.bashrc
echo 'export OCP_PASSWD=r3dh4t1!' >> $HOME/.bashrc
echo "export LAB_MASTER_API=https://api.cluster-764a.764a.example.opentlc.com:6443                  #   URL to OCP Master" >> $HOME/.bashrc
echo "export SUBDOMAIN_BASE=cluster-764a.764a.example.opentlc.com              #   OCP cluster domain; ie: cluster-168d.168d.example.opentlc.com  " >> $HOME/.bashrc
echo "export OCP_AMP_ADMIN_ID=api0            #   Name of 3scale API Management administrator " >> $HOME/.bashrc
echo "export API_TENANT_USERNAME=api8              #   Name of 3scale tenant admin " >> $HOME/.bashrc
echo "export API_TENANT_PASSWORD=admin              #   Password of 3scale tenant admin " >> $HOME/.bashrc
#########################################################################


source $HOME/.bashrc


echo "export ERDEMO_USER=user$ERD_ID              # Emergency Response Demo user" >> $HOME/.bashrc
echo "export ERDEMO_NS=$ERDEMO_USER-er-demo      # Emergency Response namespace" >> $HOME/.bashrc
echo "export SM_CP_ADMIN=admin$LAB_ID             # Service Mesh control plan admin" >> $HOME/.bashrc
echo "export SM_CP_NS=$SM_CP_ADMIN-istio-system  # Service Mesh control plane namespace" >> $HOME/.bashrc

echo "export API_MANAGER_NS=3scale-mt-$OCP_AMP_ADMIN_ID      #  Namespace of 3scale API Mgmt control plane "   >> ~/.bashrc
echo "export GW_PROJECT=user$LAB_ID-gw                      #  Namespace of 3scale API gateways" >> ~/.bashrc

echo "export OCP_USER_ID=user$LAB_ID"  >> ~/.bashrc
echo "export INCIDENT_SERVICE_API_KEY=1223b617d556a8114dc933a6c57ed81d" >> $HOME/.bashrc
echo "export INCIDENT_SERVICE_ID=25" >> $HOME/.bashrc

source $HOME/.bashrc


chmod 775 $HOME/lab/set_env_vars.sh
$HOME/lab/set_env_vars.sh

oc login $LAB_MASTER_API -u $ERDEMO_USER -p $OCP_PASSWD

oc get projects

oc login -u $SM_CP_ADMIN -p $OCP_PASSWD

oc get deploy istio-operator -n istio-operator

oc get daemonset istio-node -n istio-operator

oc describe daemonset istio-node -n istio-operator | grep Image

oc get crd --as=system:admin | grep 'maistra\|istio'

oc get mutatingwebhookconfiguration --as=system:admin | grep $SM_CP_NS

oc get mutatingwebhookconfiguration istio-sidecar-injector-$SM_CP_NS \
       -o yaml \
       --as=system:admin \
       > $HOME/lab/$SM_CP_NS-mutatingwebhookconfiguration.yaml

oc login -u $SM_CP_ADMIN -p $OCP_PASSWD

istioctl version --remote=true -i $SM_CP_ADMIN-istio-system

oc get deployments -n $SM_CP_NS

oc get ServiceMeshControlPlane -n $SM_CP_NS
# full-install   True

oc get RoleBinding -n $SM_CP_NS

oc get ServiceMeshMemberRoll default -o template --template='{{"\n"}}{{.spec}}{{"\n\n"}}' -n $SM_CP_NS

oc get statefulset -l application=datagrid-service -n $ERDEMO_NS

oc project $ERDEMO_USER-er-demo

echo -en "\n\nhttps://$(oc get route $ERDEMO_USER-emergency-console -o template --template={{.spec.host}} -n $ERDEMO_NS)\n\n"

oc login -u $OCP_USER_ID -p $OCP_PASSWD

echo -en "\n\nhttps://$(oc get routes -n $API_MANAGER_NS | grep admin | grep $OCP_USER_ID | awk '{print $2}')\n"

echo $API_TENANT_USERNAME
echo $API_TENANT_PASSWORD

oc get dc -n $GW_PROJECT

echo $(oc get secret apicast-configuration-url-secret -o yaml -n $GW_PROJECT | grep password | awk '{print $2}' | base64 -d)

echo "export INCIDENT_SERVICE_API_KEY=1223b617d556a8114dc933a6c57ed81d" >> $HOME/.bashrc

echo "export SYSTEM_PROVIDER_URL=$(oc get routes -n $API_MANAGER_NS | grep admin | grep $OCP_USER_ID | awk '{print $2}')" >> $HOME/.bashrc

echo "export API_ADMIN_ACCESS_TOKEN=$(oc get secret apicast-configuration-url-secret -o yaml -n $GW_PROJECT | grep password | awk '{print $2}' | base64 -d | cut -d'@' -f1 | cut -d'/' -f3)" >> $HOME/.bashrc

curl -v https://$(oc get route -n $API_MANAGER_NS | grep $OCP_USER_ID | grep prod | awk '{print $2}')/incidents?user_key=$INCIDENT_SERVICE_API_KEY

curl -v https://$(oc get route -n $API_MANAGER_NS | grep $OCP_USER_ID | grep prod | awk '{print $2}')/incidents?user_key=FAKEKEY

echo "apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
  - $ERDEMO_NS" | oc apply -n $SM_CP_NS -f -

echo -en "\n\n$(oc get project $ERDEMO_NS -o template --template='{{.metadata.labels}}')\n\n"
# map[kiali.io/member-of:admin8-istio-system maistra.io/member-of:admin8-istio-system]

oc get RoleBinding  -n $ERDEMO_NS -l release=istio

oc get NetworkPolicy istio-mesh -n $ERDEMO_NS

curl https://raw.githubusercontent.com/gpe-mw-training/ocp_service_mesh_advanced/master/utils/inject_istio_annotation.sh \
    -o $HOME/lab/inject_istio_annotation.sh && \
    chmod 775 $HOME/lab/inject_istio_annotation.sh && \
    $HOME/lab/inject_istio_annotation.sh

oc get pods -l group=erd-services -n $ERDEMO_NS

for POD_NAME in $(oc get pods -n $ERDEMO_NS -l group=erd-services -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}')
do
    oc get pod $POD_NAME  -n $ERDEMO_NS -o jsonpath='{.metadata.name}{"    :\t\t"}{.spec.containers[*].name}{"\n"}'
done

curl https://raw.githubusercontent.com/gpe-mw-training/ocp_service_mesh_advanced/master/utils/delete_pod_deploys.sh \
    -o $HOME/lab/delete_pod_deploys.sh && \
    chmod 775 $HOME/lab/delete_pod_deploys.sh

$HOME/lab/delete_pod_deploys.sh

# Delete completed *-deploy pods
for POD_NAME in $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' -n $ERDEMO_USER-er-demo | grep deploy ) 
do
  echo -en "Deleting: $POD_NAME\n"
  oc delete pod $POD_NAME -n $ERDEMO_USER-er-demo
done

# delete completed *-hook-post pods
for POD_NAME in $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' -n $ERDEMO_USER-er-demo | grep hook-post ) 
do
  echo -en "Deleting: $POD_NAME\n"
  oc delete pod $POD_NAME -n $ERDEMO_USER-er-demo
done

oc get pod -n $ERDEMO_NS \
       $(oc get pod -n $ERDEMO_NS | grep "^$ERDEMO_USER-responder-service" | awk '{print $1}') \
       -o json \
       | jq .spec.containers[1] \
        > $HOME/lab/responder_envoy.json

oc describe pod user28-responder-service-2-bnpkk | grep cri-o
oc get pod user28-responder-service-2-bnpkk -o json | jq .spec.nodeName

oc login -u $ERDEMO_USER -p $OCP_PASSWD

oc rsh `oc get pod -n $ERDEMO_NS | grep "responder-service" | grep "Running" | awk '{print $1}'` \
   curl http://localhost:15000/clusters?format=json \
   > $HOME/lab/responder-service-clusters.json

istioctl proxy-config cluster -n $ERDEMO_NS user8-responder-service-2-llz28 -o json

oc rsh `oc get pod -n $ERDEMO_NS | grep "responder-service" | awk '{print $1}'` \
         curl http://localhost:15000/config_dump \
         > $HOME/lab/config_dump \
         && less $HOME/lab/config_dump \
         | jq ".configs | last | .dynamic_route_configs"

oc get networkpolicy -n $ERDEMO_NS

oc get networkpolicy istio-mesh -n $ERDEMO_NS -o yaml

oc rsh -n $GW_PROJECT stage-apicast-1-25g79

oc delete networkpolicy allow-from-all-namespaces -n $ERDEMO_NS
oc delete networkpolicy allow-from-ingress-namespace -n $ERDEMO_NS

curl http://$ERDEMO_USER-incident-service.apps.$SUBDOMAIN_BASE/incidents

####################################################################
## security
##

oc login $LAB_MASTER_API -u $SM_CP_ADMIN -p $OCP_PASSWD

oc get servicemeshcontrolplane -n $SM_CP_NS

oc get servicemeshcontrolplane full-install -o yaml -n $SM_CP_NS

oc get servicemeshpolicy default -o yaml -n $SM_CP_NS

oc get secret istio.incident-service -o jsonpath={.data.cert-chain\\.pem} -n $ERDEMO_NS | base64 --decode

oc get secret istio.disaster-simulator-service -o jsonpath={.data.cert-chain\\.pem} -n $ERDEMO_NS | base64 --decode

echo "
[ req ]
req_extensions     = req_ext
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
commonName=$ERDEMO_USER.apps.$SUBDOMAIN_BASE

[req_ext]
subjectAltName   = @alt_names

[alt_names]
DNS.1  = $ERDEMO_USER.apps.$SUBDOMAIN_BASE
DNS.2  = *.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
" > cert.cfg

openssl req -x509 -config cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt

oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n $SM_CP_NS

oc patch deployment istio-ingressgateway -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date +%FT%T%z`'"}}}}}' -n $SM_CP_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: erd-wildcard-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    hosts:
    - \"*.$ERDEMO_USER.apps.$SUBDOMAIN_BASE\"
" > wildcard-gateway.yml

oc create -f wildcard-gateway.yml -n $SM_CP_NS

oc edit dc $ERDEMO_USER-incident-service -o yaml -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-incident-service --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-incident-service\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

oc edit servicemeshcontrolplane full-install -o yaml -n $SM_CP_NS
# apiVersion: maistra.io/v1
# kind: ServiceMeshControlPlane
# metadata:
#   [...]
#   name: full-install
#   [...]
# spec:
#   istio:
#     [...]
#     tracing:
#       enabled: true
#     sidecarInjectorWebhook:
#       rewriteAppHTTPProbe: true
#   [...]

oc rollout latest dc/$ERDEMO_USER-incident-service -n $ERDEMO_NS

oc edit dc $ERDEMO_USER-incident-service -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/actuator/health'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/actuator/health'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]

oc patch dc $ERDEMO_USER-incident-service --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: incident-service-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-incident-service
" > incident-service-policy.yml

oc create -f incident-service-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: incident-service-client-mtls
spec:
  host: $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > incident-service-mtls-destinationrule.yml

oc create -f incident-service-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: incident-service-virtualservice
spec:
  hosts:
  - incident-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /incidents
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
" > incident-service-virtualservice.yml

oc create -f incident-service-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: \"true\"
  labels:
    app: incident-service
  name: incident-service-gateway
spec:
  host: incident-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > incident-service-gateway.yml

oc create -f incident-service-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-incident-service -n $ERDEMO_NS

curl -v -k https://incident-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/incidents

ISTIO_INGRESSGATEWAY_POD=$(oc get pod -l app=istio-ingressgateway -o jsonpath={.items[0].metadata.name} -n $SM_CP_NS)
istioctl -n $SM_CP_NS -i $SM_CP_NS authn tls-check ${ISTIO_INGRESSGATEWAY_POD} $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local

oc edit dc $ERDEMO_USER-responder-service -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/actuator/health'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/actuator/health'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]

oc patch dc $ERDEMO_USER-responder-service --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]},"initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]},"initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-responder-service --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-responder-service\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: responder-service-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-responder-service
" > responder-service-policy.yml

oc create -f responder-service-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: responder-service-client-mtls
spec:
  host: $ERDEMO_USER-responder-service.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > responder-service-mtls-destinationrule.yml

oc create -f responder-service-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: responder-service-virtualservice
spec:
  hosts:
  - \"responder-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE\"
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /responders
    - uri:
        prefix: /responder
    - uri:
        exact: /stats
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-responder-service.$ERDEMO_NS.svc.cluster.local
" > responder-service-virtualservice.yml

oc create -f responder-service-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: responder-service
  name: responder-service-gateway
spec:
  host: "responder-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE"
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > responder-service-gateway.yml

oc create -f responder-service-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-responder-service -n $ERDEMO_NS

curl -v -k https://responder-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/responders/available

oc edit dc $ERDEMO_USER-disaster-simulator -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
oc patch dc $ERDEMO_USER-disaster-simulator --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080"]}, "initialDelaySeconds": 10, "timeoutSeconds": 1, "periodSeconds": 10, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080"]},"initialDelaySeconds": 10, "timeoutSeconds": 1, "periodSeconds": 10, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-disaster-simulator --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-disaster-simulator\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: disaster-simulator-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-disaster-simulator
" > disaster-simulator-policy.yml

oc create -f disaster-simulator-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: disaster-simulator-client-mtls
spec:
  host: $ERDEMO_USER-disaster-simulator.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > disaster-simulator-mtls-destinationrule.yml

oc create -f disaster-simulator-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: disaster-simulator-virtualservice
spec:
  hosts:
  - disaster-simulator.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-disaster-simulator.$ERDEMO_NS.svc.cluster.local
" > disaster-simulator-virtualservice.yml

oc create -f disaster-simulator-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: disaster-simulator
  name: disaster-simulator-gateway
spec:
  host: disaster-simulator.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > disaster-simulator-gateway.yml

oc create -f disaster-simulator-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-disaster-simulator -n $ERDEMO_NS

curl -v -k https://disaster-simulator.$ERDEMO_USER.apps.$SUBDOMAIN_BASE

oc edit dc $ERDEMO_USER-incident-priority-service -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/health'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/health'
#           initialDelaySeconds: 10
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
oc patch dc $ERDEMO_USER-incident-priority-service --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/health"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/health"]},"initialDelaySeconds": 10, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-incident-priority-service --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-incident-priority-service\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: incident-priority-service-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-incident-priority-service
" > incident-priority-service-policy.yml

oc create -f incident-priority-service-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: incident-priority-service-client-mtls
spec:
  host: $ERDEMO_USER-incident-priority-service.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > incident-priority-service-mtls-destinationrule.yml

oc create -f incident-priority-service-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: incident-priority-service-virtualservice
spec:
  hosts:
  - incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /priority
    - uri:
        exact: /reset
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-incident-priority-service.$ERDEMO_NS.svc.cluster.local
" > incident-priority-service-virtualservice.yml

oc create -f incident-priority-service-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: incident-priority-service
  name: incident-priority-service-gateway
spec:
  host: incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > incident-priority-service-gateway.yml

oc create -f incident-priority-service-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-incident-priority-service -n $ERDEMO_NS

curl -v -k https://incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/priority/qwerty

oc edit dc $ERDEMO_USER-process-service -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/actuator/health'
#           initialDelaySeconds: 60
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/actuator/health'
#           initialDelaySeconds: 45
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
oc patch dc $ERDEMO_USER-process-service --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/acuator/health"]},"initialDelaySeconds": 60, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]},"initialDelaySeconds": 45, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-process-service --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-process-service\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: process-service-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-process-service
" > process-service-policy.yml

oc create -f process-service-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: process-service-client-mtls
spec:
  host: $ERDEMO_USER-process-service.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > process-service-mtls-destinationrule.yml

oc create -f process-service-mtls-destinationrule.yml -n $ERDEMO_NS

oc edit dc $ERDEMO_USER-mission-service -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 10
#           periodSeconds: 10
#           timeoutSeconds: 1
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 10
#           periodSeconds: 10
#           timeoutSeconds: 1
# [...]
oc patch dc $ERDEMO_USER-mission-service --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080"]},"initialDelaySeconds": 10, "timeoutSeconds": 1, "periodSeconds": 10, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080"]},"initialDelaySeconds": 10, "timeoutSeconds": 1, "periodSeconds": 10, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-mission-service --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-mission-service\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: mission-service-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-mission-service
" > mission-service-policy.yml

oc create -f mission-service-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: mission-service-client-mtls
spec:
  host: $ERDEMO_USER-mission-service.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > mission-service-mtls-destinationrule.yml

oc create -f mission-service-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: mission-service-virtualservice
spec:
  hosts:
  - mission-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-mission-service.$ERDEMO_NS.svc.cluster.local
" > mission-service-virtualservice.yml

oc create -f mission-service-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: mission-service
  name: mission-service-gateway
spec:
  host: mission-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > mission-service-gateway.yml

oc create -f mission-service-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-mission-service -n $ERDEMO_NS

curl -v -k https://mission-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/api/missions

oc edit dc $ERDEMO_USER-responder-simulator -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 10
#           periodSeconds: 10
#           timeoutSeconds: 1
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 10
#           periodSeconds: 10
#           timeoutSeconds: 1
# [...]
oc patch dc $ERDEMO_USER-responder-simulator --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/metrics"]},"initialDelaySeconds": 10, "timeoutSeconds": 1, "periodSeconds": 10, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/metrics"]},"initialDelaySeconds": 10, "timeoutSeconds": 1, "periodSeconds": 10, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-responder-simulator --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-responder-simulator\",\"group\":\"erd-services\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: responder-simulator-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-responder-simulator
" > responder-simulator-policy.yml

oc create -f responder-simulator-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: responder-simulator-client-mtls
spec:
  host: $ERDEMO_USER-responder-simulator.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > responder-simulator-mtls-destinationrule.yml

oc create -f responder-simulator-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: responder-simulator-virtualservice
spec:
  hosts:
  - responder-simulator.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-responder-simulator.$ERDEMO_NS.svc.cluster.local
" > responder-simulator-virtualservice.yml

oc create -f responder-simulator-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: responder-simulator
  name: responder-simulator-gateway
spec:
  host: responder-simulator.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > responder-simulator-gateway.yml

oc create -f responder-simulator-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-responder-simulator -n $ERDEMO_NS

curl -v -k https://responder-simulator.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/stats/mc

oc edit dc $ERDEMO_USER-process-viewer -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/health'
#           initialDelaySeconds: 15
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080/health'
#           initialDelaySeconds: 5
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
oc patch dc $ERDEMO_USER-process-viewer --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/health"]},"initialDelaySeconds": 15, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/health"]},"initialDelaySeconds": 5, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-process-viewer --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-process-viewer\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: process-viewer-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-process-viewer
" > process-viewer-policy.yml

oc create -f process-viewer-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: process-viewer-client-mtls
spec:
  host: $ERDEMO_USER-process-viewer.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > process-viewer-mtls-destinationrule.yml

oc create -f process-viewer-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: process-viewer-virtualservice
spec:
  hosts:
  - process-viewer.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /image
    - uri:
        prefix: /data
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-process-viewer.$ERDEMO_NS.svc.cluster.local
" > process-viewer-virtualservice.yml

oc create -f process-viewer-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: process-viewer
  name: process-viewer-gateway
spec:
  host: process-viewer.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > process-viewer-gateway.yml

oc create -f process-viewer-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-process-viewer -n $ERDEMO_NS

curl -v -k https://process-viewer.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/image/process/incident-process

oc edit dc emergency-console -o yaml -n $ERDEMO_NS
# [...]
#         livenessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
#         readinessProbe:
#           failureThreshold: 3
#           exec:
#             command:
#               - curl
#               - 'http://127.0.0.1:8080'
#           initialDelaySeconds: 30
#           periodSeconds: 30
#           timeoutSeconds: 3
# [...]
oc patch dc $ERDEMO_USER-emergency-console --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080"]},"initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n $ERDEMO_NS

oc patch dc $ERDEMO_USER-emergency-console --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-emergency-console\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: emergency-console-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $ERDEMO_USER-emergency-console
" > emergency-console-policy.yml

oc create -f emergency-console-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: emergency-console-client-mtls
spec:
  host: $ERDEMO_USER-emergency-console.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > emergency-console-mtls-destinationrule.yml

oc create -f emergency-console-mtls-destinationrule.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: emergency-console-virtualservice
spec:
  hosts:
  - emergency-console.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-emergency-console.$ERDEMO_NS.svc.cluster.local
" > emergency-console-virtualservice.yml

oc create -f emergency-console-virtualservice.yml -n $ERDEMO_NS

echo "---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: 'true'
  labels:
    app: emergency-console
  name: emergency-console-gateway
spec:
  host: emergency-console.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
" > emergency-console-gateway.yml

oc create -f emergency-console-gateway.yml -n $SM_CP_NS

oc delete route $ERDEMO_USER-emergency-console -n $ERDEMO_NS

echo -en "\n\nhttps://sso-user-sso.apps.$SUBDOMAIN_BASE/auth/admin/$ERDEMO_USER-emergency-realm/console\n\n"

echo https://emergency-console.$ERDEMO_USER.apps.$SUBDOMAIN_BASE.

oc patch dc postgresql --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"postgresql\", \"name\":\"postgresql\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: postgresql-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: postgresql
" > postgresql-policy.yml

oc create -f postgresql-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: postgresql-client-mtls
spec:
  host: postgresql.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > postgresql-mtls-destinationrule.yml

oc create -f postgresql-mtls-destinationrule.yml -n $ERDEMO_NS

oc patch dc process-service-postgresql --type='json' -p "[{\"op\": \"add\", \"path\": \"/spec/template/metadata\", \"value\": {\"annotations\":{\"sidecar.istio.io/inject\": \"true\"}, \"labels\":{\"app\":\"$ERDEMO_USER-process-service\", \"name\":\"$ERDEMO_USER-process-service-postgresql\"}}}]" -n $ERDEMO_NS

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: process-postgresql-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: process-service-postgresql
" > process-postgresql-policy.yml

oc create -f process-postgresql-policy.yml -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: process-service-postgresql-client-mtls
spec:
  host: $ERDEMO_USER-process-service-postgresql.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
" > process-postgresql-mtls-destinationrule.yml

oc create -f process-postgresql-mtls-destinationrule.yml -n $ERDEMO_NS

oc patch policy incident-service-mtls --type='json' -p '[{"op":"replace","path":"/spec/peers/0/mtls/mode", "value": "STRICT"}]' -n $ERDEMO_NS

oc get policy -n $ERDEMO_NS
# NAME                             AGE
# disaster-simulator-mtls          81m
# emergency-console-mtls           48m
# incident-priority-service-mtls   61m
# incident-service-mtls            97m
# mission-service-mtls             57m
# postgresql-mtls                  42m
# process-postgresql-mtls          27m
# process-service-mtls             58m
# process-viewer-mtls              51m
# responder-service-mtls           85m
# responder-simulator-mtls         53m

oc patch servicemeshpolicy default --type='json' -p '[{"op":"replace","path":"/spec/peers/0/mtls/mode","value":"STRICT"}]' -n $SM_CP_NS

echo "---
apiVersion: rbac.maistra.io/v1
kind: ServiceMeshRbacConfig
metadata:
  name: default
spec:
  mode: ON_WITH_INCLUSION
  inclusion:
    services:
      - $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
" > servicemesh-rbac.yml

oc create -f servicemesh-rbac.yml -n $SM_CP_NS

INCIDENT_SERVICE_URL=$(oc get route incident-service-gateway -n $SM_CP_NS -o template --template={{.spec.host}})
curl -v -k https://$INCIDENT_SERVICE_URL/incidents

echo "---
apiVersion: rbac.istio.io/v1alpha1
kind: ServiceRole
metadata:
  name: incident-service-internal
spec:
  rules:
    - services: [\"$ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local\"]
      methods: [\"*\"]
" > sr-incident-service-internal.yml

oc create -f sr-incident-service-internal.yml -n $ERDEMO_NS

echo "---
apiVersion: rbac.istio.io/v1alpha1
kind: ServiceRoleBinding
metadata:
  name: incident-service-internal
spec:
  subjects:
    - properties:
        source.namespace: \"$ERDEMO_NS\"
  roleRef:
    kind: ServiceRole
    name: \"incident-service-internal\"
" > srb-incident-service-internal.yml

oc create -f srb-incident-service-internal.yml -n $ERDEMO_NS

echo "---
apiVersion: rbac.istio.io/v1alpha1
kind: ServiceRole
metadata:
  name: incident-service-ingress
spec:
  rules:
    - services: [\"$ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local\"]
      methods: [\"GET\"]
" > sr-incident-service-ingress.yml

oc create -f sr-incident-service-ingress.yml -n $ERDEMO_NS

echo "---
apiVersion: rbac.istio.io/v1alpha1
kind: ServiceRoleBinding
metadata:
  name: incident-service-ingress
spec:
  subjects:
    - user: \"cluster.local/ns/$SM_CP_NS/sa/istio-ingressgateway-service-account\"
  roleRef:
    kind: ServiceRole
    name: \"incident-service-ingress\"
" > srb-incident-service-ingress.yml

oc create -f srb-incident-service-ingress.yml -n $ERDEMO_NS

curl -k -v -X POST -H "Content-type: application/json" -d '{"lat": 34.14338, "lon": -77.86569, "numberOfPeople": 3, "medicalNeeded": true, "victimName": "victim",  "victimPhoneNumber": "111-111-111" }' https://$INCIDENT_SERVICE_URL/incidents

echo -en "\n\nhttps://sso-user-sso.apps.$SUBDOMAIN_BASE/auth/admin/$ERDEMO_USER-emergency-realm/console\n\n"

export RHSSO_URL=https://sso-user-sso.apps.$SUBDOMAIN_BASE
export REALM=$ERDEMO_USER-emergency-realm
export USER=wangzheng
export PASSWD=test
TKN=$(curl -X POST "$RHSSO_URL/auth/realms/$REALM/protocol/openid-connect/token" \
 -H "Content-Type: application/x-www-form-urlencoded" \
 -d "username=$USER" \
 -d "password=$PASSWD" \
 -d "grant_type=password" \
 -d "client_id=curl" \
  --insecure \
 | sed 's/.*access_token":"//g' | sed 's/".*//g')
echo $TKN

echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: ingressgateway-origin
spec:
  targets:
    - name: istio-ingressgateway
  origins:
    - jwt:
        issuer: https://sso-user-sso.apps.$SUBDOMAIN_BASE/auth/realms/$ERDEMO_USER-emergency-realm
        jwksUri: https://sso-user-sso.apps.$SUBDOMAIN_BASE/auth/realms/$ERDEMO_USER-emergency-realm/protocol/openid-connect/certs
  principalBinding: USE_ORIGIN
" > ingressgateway-origin.yml

oc create -f ingressgateway-origin.yml -n $SM_CP_NS

INCIDENT_SERVICE_URL=$(oc get route incident-service-gateway -n $SM_CP_NS -o template --template={{.spec.host}})
curl -v -k https://$INCIDENT_SERVICE_URL/incidents

TKN=$(curl -X POST "$RHSSO_URL/auth/realms/$REALM/protocol/openid-connect/token" \
 -H "Content-Type: application/x-www-form-urlencoded" \
 -d "username=$USER" \
 -d "password=$PASSWD" \
 -d "grant_type=password" \
 -d "client_id=curl" \
  --insecure \
 | sed 's/.*access_token":"//g' | sed 's/".*//g')
curl -v -k -H "Authorization: Bearer $TKN" https://$INCIDENT_SERVICE_URL/incidents

oc delete policy ingressgateway-origin -n $SM_CP_NS

export ROOTCA_ORG=Istio
export ROOTCA_CN="Root CA"
export ROOTCA_DAYS=3650

echo "
[ req ]
encrypt_key = no
prompt = no
utf8 = yes
default_md = sha256
default_bits = 4096
req_extensions = req_ext
x509_extensions = req_ext
distinguished_name = req_dn
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign
[ req_dn ]
O = ${ROOTCA_ORG}
CN = ${ROOTCA_CN}
" > root-ca.conf

openssl genrsa -out root-ca.key 4096

openssl req -new -key root-ca.key -config root-ca.conf -out root-ca.csr

openssl x509 -req -days ${ROOTCA_DAYS} -signkey root-ca.key -extensions req_ext -extfile root-ca.conf -in root-ca.csr -out root-ca.crt

mkdir $SM_CP_ADMIN
export CITADEL_ORG=Istio
export CITADEL_CN="Intermediate CA"
export CITADEL_DAYS=365
export CITADEL_SERIAL=$RANDOM

echo "
[ req ]
encrypt_key = no
prompt = no
utf8 = yes
default_md = sha256
default_bits = 4096
req_extensions = req_ext
x509_extensions = req_ext
distinguished_name = req_dn
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign
subjectAltName=@san
[ san ]
URI.1 = spiffe://cluster.local/ns/${SM_CP_NS}/sa/citadel
DNS.1 = localhost
[ req_dn ]
O = ${CITADEL_ORG}
CN = ${CITADEL_CN}
L = cluster.local
" > $SM_CP_ADMIN/intermediate.conf

openssl genrsa -out $SM_CP_ADMIN/citadel-ca.key 4096

openssl req -new -config $SM_CP_ADMIN/intermediate.conf -key $SM_CP_ADMIN/citadel-ca.key -out $SM_CP_ADMIN/citadel-ca.csr

openssl x509 -req -days $CITADEL_DAYS -CA root-ca.crt -CAkey root-ca.key -set_serial $CITADEL_SERIAL -extensions req_ext -extfile $SM_CP_ADMIN/intermediate.conf -in $SM_CP_ADMIN/citadel-ca.csr -out $SM_CP_ADMIN/citadel-ca.crt

cat $SM_CP_ADMIN/citadel-ca.crt root-ca.crt > $SM_CP_ADMIN/citadel-ca-chain.crt

oc create secret generic cacerts -n $SM_CP_NS --from-file=ca-cert.pem=$SM_CP_ADMIN/citadel-ca.crt --from-file=ca-key.pem=$SM_CP_ADMIN/citadel-ca.key --from-file=root-cert.pem=root-ca.crt --from-file=cert-chain.pem=$SM_CP_ADMIN/citadel-ca-chain.crt

oc edit servicemeshcontrolplane full-install -n $SM_CP_NS
# apiVersion: maistra.io/v1
# kind: ServiceMeshControlPlane
# metadata:
#   [...]
# spec:
#   istio:
#     [...]
#     pilot:
#       autoscaleEnabled: false
#       traceSampling: 100
#     security:
#       selfSigned: false
#     tracing:
#       enabled: true
#   threeScale:
#     enabled: false

oc get deployment istio-citadel -o yaml -n $SM_CP_NS

oc get secret -n $ERDEMO_NS | grep "istio." | awk '{print $1}' | xargs -I istio-secret oc delete secret istio-secret -n $ERDEMO_NS

oc get secret istio.incident-service -o jsonpath={.data.cert-chain\\.pem} -n $ERDEMO_NS | base64 --decode

for dc in disaster-simulator emergency-console incident-priority-service incident-service mission-service process-service process-viewer responder-service responder-simulator
do
  oc rollout latest dc/$ERDEMO_USER-$dc -n $ERDEMO_NS
done

###########################################################3
## Istio Reliability: Retries, Timeouts and Circuit Breaker
##

oc login -u $ERDEMO_USER

oc patch dc $ERDEMO_USER-incident-priority-service -p "{\"spec\":{\"triggers\":[{\"type\": \"ConfigChange\"},{\"type\": \"ImageChange\",\"imageChangeParams\": {\"automatic\": true, \"containerNames\":[\"$ERDEMO_USER-incident-priority-service\"], \"from\": {\"kind\": \"ImageStreamTag\", \"namespace\": \"$ERDEMO_NS\", \"name\": \"$ERDEMO_USER-incident-priority-service:1.0.0-fault\"}}}]}}" -n $ERDEMO_NS

oc scale dc $ERDEMO_USER-incident-priority-service --replicas=3 -n $ERDEMO_NS

INCIDENT_PRIORITY_SERVICE_POD=$(oc get pods -n $ERDEMO_NS|grep Running|grep $ERDEMO_USER-incident-priority-service.*|awk '{ print $1 }'|head -1)

oc get pod -n $ERDEMO_NS | grep incident-priority

oc exec -it $INCIDENT_PRIORITY_SERVICE_POD -n $ERDEMO_NS -c $ERDEMO_USER-incident-priority-service /bin/bash

curl -v -X POST -d '{"error":503,"percentage":100}' http://127.0.0.1:9080/inject

while :; do curl -k -s -w %{http_code} --output /dev/null https://incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/priority/qwerty; echo "";sleep .1; done

siege -r 10 -c 1 -v https://incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/priority/qwerty

oc logs -f $INCIDENT_PRIORITY_SERVICE_POD -c $ERDEMO_USER-incident-priority-service -n $ERDEMO_NS

while :; do curl -k -s -w %{http_code} --output /dev/null https://incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/priority/qwerty; echo "";sleep .1; done

curl -X POST http://127.0.0.1:9080/reset

oc exec -it user8-incident-priority-service-5-x4rfd /bin/bash

curl -X POST -d '{"error":500,"percentage":100}' http://127.0.0.1:9080/inject

oc edit virtualservice incident-priority-service-virtualservice -o yaml -n $ERDEMO_NS
# kind: VirtualService
# apiVersion: networking.istio.io/v1alpha3
# [...]
# spec:
#   hosts:
#     - >-
#       incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
#   gateways:
#     - erd-wildcard-gateway.$SM_CP_ADMIN-istio-system.svc.cluster.local
#   http:
#     - match:
#         - uri:
#             prefix: /priority
#         - uri:
#             exact: /reset
#       route:
#         - destination:
#             host: $ERDEMO_USER-incident-priority-service.$ERDEMO_USER-er-demo.svc.cluster.local
#             port:
#               number: 8080
#       retries:
#         attempts: 2
#         retryOn: 5xx

INCIDENT_PRIORITY_SERVICE_POD=$(oc get pods -n $ERDEMO_NS|grep Running|grep $ERDEMO_USER-incident-priority-service.*|awk '{ print $1 }'|head -1)

oc exec -it $INCIDENT_PRIORITY_SERVICE_POD -n $ERDEMO_NS -c $ERDEMO_USER-incident-priority-service /bin/bash

curl -X POST -d '{"delay":2000,"percentage":100}' http://127.0.0.1:9080/inject

oc edit virtualservice incident-priority-service-virtualservice -o yaml -n $ERDEMO_NS
# kind: VirtualService
# apiVersion: networking.istio.io/v1alpha3
# [...]
# spec:
#   hosts:
#     - >-
#       incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
#   gateways:
#     - erd-wildcard-gateway.$SM_CP_ADMIN-istio-system.svc.cluster.local
#   http:
#     - match:
#         - uri:
#             prefix: /priority
#         - uri:
#             exact: /reset
#       route:
#         - destination:
#             host: $ERDEMO_USER-incident-priority-service.$ERDEMO_USER-er-demo.svc.cluster.local
#             port:
#               number: 8080
#       timeout: 500ms

while :; do curl -k -s -w %{http_code} --output /dev/null https://incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/priority/qwerty; echo "";sleep .1; done

# kind: VirtualService
# apiVersion: networking.istio.io/v1alpha3
# [...]
# spec:
#   hosts:
#     - >-
#       incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
#   gateways:
#     - erd-wildcard-gateway.$SM_CP_ADMIN-istio-system.svc.cluster.local
#   http:
#     - match:
#         - uri:
#             prefix: /priority
#         - uri:
#             exact: /reset
#       route:
#         - destination:
#             host: $ERDEMO_USER-incident-priority-service.$ERDEMO_USER-er-demo.svc.cluster.local
#             port:
#               number: 8080
#       retries:
#         attempts: 2
#         retryOn: 5xx
#         perTryTimeout: 200ms

oc exec -it $INCIDENT_PRIORITY_SERVICE_POD -n $ERDEMO_NS -c $ERDEMO_USER-incident-priority-service /bin/bash

curl -X POST -d '{"error":503,"percentage":100}' http://127.0.0.1:9080/inject

siege -r 100 -c 4 -d0 -v https://incident-priority-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE/priority/qwerty

##################################################################
## Observability Lab: Distributed Tracing
##

oc login $LAB_MASTER_API -u $SM_CP_ADMIN -p $OCP_PASSWD

oc describe servicemeshcontrolplane full-install -n $SM_CP_NS

echo -en "\n\nhttps://$(oc get route jaeger -o template --template={{.spec.host}} -n $SM_CP_NS)\n\n"

oc edit configmap incident-service -n $ERDEMO_NS
# opentracing.jaeger.enabled=true
# opentracing.jaeger.service-name=incident-service
# opentracing.jaeger.http-sender.url=http://jaeger-collector.<admin user>-istio-system.svc:14268/api/traces
# opentracing.jaeger.probabilistic-sampler.sampling-rate=1
# opentracing.jaeger.enable-b3-propagation=true

oc patch dc $ERDEMO_USER-incident-service -p "{\"spec\":{\"triggers\":[{\"type\": \"ConfigChange\"},{\"type\": \"ImageChange\",\"imageChangeParams\": {\"automatic\": true, \"containerNames\":[\"$ERDEMO_USER-incident-service\"], \"from\": {\"kind\": \"ImageStreamTag\", \"namespace\": \"$ERDEMO_NS\", \"name\": \"$ERDEMO_USER-incident-service:1.0.0-jaeger\"}}}]}}" -n $ERDEMO_NS

#################################################################
## Observability Lab: Metrics and Monitoring
##

oc login $LAB_MASTER_API -u $SM_CP_ADMIN -p $OCP_PASSWD

oc patch dc $ERDEMO_USER-incident-service -p '{"spec":{"template":{"metadata":{"labels":{"version":"v1"}}}}}' -n $ERDEMO_NS

echo "---
apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  labels:
    app: $ERDEMO_USER-incident-service
  name: $ERDEMO_USER-incident-service-v2
spec:
  replicas: 1
  revisionHistoryLimit: 2
  selector:
    app: $ERDEMO_USER-incident-service
    group: erd-services
  strategy:
    activeDeadlineSeconds: 21600
    resources: {}
    rollingParams:
      intervalSeconds: 1
      maxSurge: 25%
      maxUnavailable: 25%
      timeoutSeconds: 3600
      updatePeriodSeconds: 1
    type: Rolling
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: \"true\"
      creationTimestamp: null
      labels:
        app: $ERDEMO_USER-incident-service
        group: erd-services
        version: v2
    spec:
      containers:
      - env:
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - curl
            - http://127.0.0.1:8080/actuator/health
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 30
          successThreshold: 1
          timeoutSeconds: 3
        name: $ERDEMO_USER-incident-service
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        readinessProbe:
          exec:
            command:
            - curl
            - http://127.0.0.1:8080/actuator/health
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 30
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          limits:
            cpu: 500m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          privileged: false
          procMount: Default
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /app/logging
          name: logging
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: incident-service
      serviceAccountName: incident-service
      terminationGracePeriodSeconds: 30
      volumes:
      - configMap:
          defaultMode: 420
          name: incident-service-logging
        name: logging
  test: false
  triggers:
  - type: ConfigChange
  - imageChangeParams:
      automatic: true
      containerNames:
      - $ERDEMO_USER-incident-service
      from:
        kind: ImageStreamTag
        name: $ERDEMO_USER-incident-service:1.0.0-jaeger
        namespace: $ERDEMO_NS
    type: ImageChange
" | oc create -f - -n $ERDEMO_NS

oc get service $ERDEMO_USER-incident-service -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.selector -n $ERDEMO_NS

oc describe service $ERDEMO_USER-incident-service -n $ERDEMO_NS | grep Endpoints

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: incident-service-client-mtls
spec:
  host: $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
" | oc apply -f - -n $ERDEMO_NS

echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: incident-service-virtualservice
spec:
  hosts:
  - incident-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
    - match:
        - uri:
            prefix: /incidents
      route:
        - destination:
            host: $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
            port:
              number: 8080
            subset: v1
          weight: 20
        - destination:
            host: $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local
            port:
              number: 8080
            subset: v2
          weight: 80
" | oc apply -f - -n $ERDEMO_NS

echo "---
apiVersion: config.istio.io/v1alpha2
kind: instance
metadata:
  name: version-count
spec:
  compiledTemplate: metric
  params:
    value: \"1\"
    dimensions:
      source: source.workload.name | \"unknown\"
      version: destination.labels[\"version\"] | \"unknown\"
      destination: destination.service.name | \"unknown\"
    monitored_resource_type: '\"UNSPECIFIED\"'
"  | oc create -f - -n $ERDEMO_NS

echo "---
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: version-count-handler
spec:
  compiledAdapter: prometheus
  params:
    metrics:
    - name: version_count
      instance_name: version-count.instance.$ERDEMO_NS
      kind: COUNTER
      label_names:
      - source
      - version
      - destination
" | oc create -f - -n $ERDEMO_NS

oc extract cm/prometheus -n $SM_CP_NS --to=. --keys=prometheus.yml
# global:
#   scrape_interval: 15s
#   evaluation_interval: 15s

# rule_files:
# - "*.rules"

# [...]

echo "
groups:
  - name: ingress_gateway
    rules:
      - record: ingress:request_duration_seconds:histogram_quantile
        expr: histogram_quantile(0.5 ,sum(irate(istio_request_duration_seconds_bucket{source_workload=\"istio-ingressgateway\"} [1m])) by (destination_workload, le))
        labels:
          quantile: \"0.5\"
      - record: ingress:request_duration_seconds:histogram_quantile
        expr: histogram_quantile(0.9, sum(irate(istio_request_duration_seconds_bucket{source_workload=\"istio-ingressgateway\"} [1m])) by (destination_workload, le))
        labels:
          quantile: \"0.9\"
      - record: ingress:request_duration_seconds:histogram_quantile
        expr: histogram_quantile(0.99,sum(irate(istio_request_duration_seconds_bucket{source_workload=\"istio-ingressgateway\"} [1m])) by (destination_workload, le))
        labels:
          quantile: \"0.99\"
" > ingress.rules

echo "
groups:
  - name: ingress_gateway_alerts
    rules:
      - alert: IncidentServiceHighResponseTime
        expr:  ingress:request_duration_seconds:histogram_quantile{quantile=\"0.9\",destination_workload=~\"^$ERDEMO_USER-incident-service.*\"} > 1
        for: 30s
        labels:
          severity: high
        annotations:
          message: The Incident Service has a 90th percentile response time of {{ \$value }} seconds for destination {{ \$labels.destination_workload }}.
" > ingress-alert.rules

oc delete configmap prometheus -n $SM_CP_NS
oc create configmap prometheus -n $SM_CP_NS --from-file=prometheus.yml --from-file=ingress.rules --from-file=ingress-alert.rules --save-config=true
oc label configmap prometheus -n $SM_CP_NS app=prometheus app.kubernetes.io/component=prometheus app.kubernetes.io/instance=$SM_CP_NS app.kubernetes.io/managed-by=maistra-istio-operator app.kubernetes.io/name=prometheus app.kubernetes.io/part-of=istio app.kubernetes.io/version=1.0.1-8.el8-1 chart=prometheus heritage=Tiller maistra.io/owner=$SM_CP_NS release=istio

oc patch deployment prometheus -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date -Iseconds`'"}}}}}' -n $SM_CP_NS

# ingress:request_duration_seconds:histogram_quantile{destination_workload=~"^$ERDEMO_USER-incident-service.*"}.





```