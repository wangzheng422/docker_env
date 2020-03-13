```bash
oc new-project bookinfo

oc apply -f https://raw.githubusercontent.com/istio/istio/1.4.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo

oc expose service productpage

echo -en "\n$(oc get route productpage --template '{{ .spec.host }}')\n"

oc new-project bookretail-istio-system --display-name="Service Mesh System"

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

oc get deploy -n bookinfo -o json > test
cat test | jq -r .items[].metadata.name | xargs -I DEMO oc patch deploy DEMO -p '{"spec":{"template": { "metadata" : { "annotations" : {  "sidecar.istio.io/inject": "false" } }   } }}'

oc get servicemeshpolicy default -o yaml -n bookretail-istio-system

oc get networkpolicy -n bookinfo

echo "
[ req ]
req_extensions     = req_ext
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
commonName=5064.apps.sandbox1845.opentlc.com

[req_ext]
subjectAltName   = @alt_names

[alt_names]
DNS.1  = apps.cluster-5064.5064.sandbox1845.opentlc.com
DNS.2  = *.apps.cluster-5064.5064.sandbox1845.opentlc.com
" > cert.cfg

openssl req -x509 -config cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt

oc delete secret istio-ingressgateway-certs -n bookretail-istio-system

oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n bookretail-istio-system

oc patch deployment istio-ingressgateway -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date +%FT%T%z`'"}}}}}' -n bookretail-istio-system

cat << EOF > wildcard-gateway.yml
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: wildcard-gateway
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
    - "*.apps.cluster-5064.5064.sandbox1845.opentlc.com"
EOF

oc apply -f wildcard-gateway.yml -n bookretail-istio-system

oc get Gateway -n bookretail-istio-system

cat << EOF > test.yml
---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: details-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: details
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: details-mtls
spec:
  host: details.bookinfo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details-virtualservice
spec:
  hosts:
  - details.apps.cluster-5064.5064.sandbox1845.opentlc.com
  gateways:
  - wildcard-gateway.bookretail-istio-system.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9080
        host: details.bookinfo.svc.cluster.local
---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: productpage-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: productpage
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage-mtls
spec:
  host: productpage.bookinfo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage-virtualservice
spec:
  hosts:
  - productpage.apps.cluster-5064.5064.sandbox1845.opentlc.com
  gateways:
  - wildcard-gateway.bookretail-istio-system.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9080
        host: productpage.bookinfo.svc.cluster.local
---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: ratings-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: ratings
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings-mtls
spec:
  host: ratings.bookinfo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-virtualservice
spec:
  hosts:
  - ratings.apps.cluster-5064.5064.sandbox1845.opentlc.com
  gateways:
  - wildcard-gateway.bookretail-istio-system.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9080
        host: ratings.bookinfo.svc.cluster.local
---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: reviews-mtls
spec:
  peers:
  - mtls:
      mode: STRICT
  targets:
  - name: reviews
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-mtls
spec:
  host: reviews.bookinfo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-virtualservice
spec:
  hosts:
  - reviews.apps.cluster-5064.5064.sandbox1845.opentlc.com
  gateways:
  - wildcard-gateway.bookretail-istio-system.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9080
        host: reviews.bookinfo.svc.cluster.local

EOF

oc apply -f test.yml -n bookinfo

oc create -f test.yml -n bookinfo

cat << EOF > test-mc.yml
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: "true"
  labels:
    app: details
  name: details-gateway
spec:
  host: details.apps.cluster-5064.5064.sandbox1845.opentlc.com
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: "true"
  labels:
    app: productpage
  name: productpage-gateway
spec:
  host: productpage.apps.cluster-5064.5064.sandbox1845.opentlc.com
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: "true"
  labels:
    app: ratings
  name: ratings-gateway
spec:
  host: ratings.apps.cluster-5064.5064.sandbox1845.opentlc.com
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
    openshift.io/host.generated: "true"
  labels:
    app: reviews
  name: reviews-gateway
spec:
  host: reviews.apps.cluster-5064.5064.sandbox1845.opentlc.com
  port:
    targetPort: https
  tls:
    termination: passthrough
  to:
    kind: Service
    name: istio-ingressgateway
    weight: 100
  wildcardPolicy: None
EOF

oc apply -f test-mc.yml -n bookretail-istio-system



```