```bash


var_namespace='demo-playground'

# create demo project
oc new-project $var_namespace


# create the macvlan config
# please notice, we have ip address configured.
oc delete -f ${BASE_DIR}/data/install/macvlan-test.conf

var_namespace='demo-playground'
cat << EOF > ${BASE_DIR}/data/install/macvlan-test.conf
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: $var_namespace-macvlan-01
  namespace: $var_namespace
spec:
  config: |- 
    {
      "cniVersion": "0.3.1",
      "name": "macvlan-net",
      "type": "macvlan",
      "_master": "eth1",
      "linkInContainer": false,
      "mode": "bridge",
      "ipam": {
          "type": "static",
          "_addresses": [
            {
              "address": "192.168.99.191/24"
            },
            {
              "address": "192.168.99.192/24"
            },
            {
              "address": "192.168.99.193/24"
            }
          ]
        }
    }

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tinypod-01
  namespace: $var_namespace
  labels:
    app: tinypod-01
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tinypod-01
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: '[
          {
            "name": "$var_namespace-macvlan-01", 
            "_mac": "02:03:04:05:06:07", 
            "_interface": "myiface1", 
            "ips": [
              "192.168.99.191/24"
              ] 
          }
        ]'
      labels:
        app: tinypod-01
        wzh-run: tinypod-testing
    spec:
      containers:
      - image: registry.k8s.io/e2e-test-images/agnhost:2.43
        imagePullPolicy: IfNotPresent
        name: agnhost-container
        command: [ "/agnhost", "serve-hostname"]
# ---
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: tinypod-02
#   namespace: $var_namespace
#   labels:
#     app: tinypod-02
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: tinypod-02
#   template:
#     metadata:
#       annotations:
#         k8s.v1.cni.cncf.io/networks: '[
#           {
#             "name": "$var_namespace-macvlan-01", 
#             "_mac": "02:03:04:05:06:07", 
#             "_interface": "myiface1", 
#             "ips": [
#               "192.168.99.192/24"
#               ] 
#           }
#         ]'
#       labels:
#         app: tinypod-02
#         wzh-run: tinypod-testing
#     spec:
#       containers:
#       - image: registry.k8s.io/e2e-test-images/agnhost:2.43
#         imagePullPolicy: IfNotPresent
#         name: agnhost-container
#         command: [ "/agnhost", "serve-hostname"]
EOF

oc apply -f ${BASE_DIR}/data/install/macvlan-test.conf

```