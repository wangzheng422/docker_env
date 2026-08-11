# Create namespaces
oc create ns ns-blue
oc create ns ns-red

# Deploy Test Pods (CentOS)
# Using quay.io/wangzheng422/qimgs:centos9-test-2025.12.18.v01 as it has curl/network tools
oc create deployment test-pod --image=quay.io/wangzheng422/qimgs:centos9-test-2025.12.18.v01 -n ns-blue
oc create deployment test-pod --image=quay.io/wangzheng422/qimgs:centos9-test-2025.12.18.v01 -n ns-red

# Create AdminPolicyBasedExternalRoute for ns-blue
cat <<EOF | oc apply -f -
apiVersion: k8s.ovn.org/v1
kind: AdminPolicyBasedExternalRoute
metadata:
  name: ns-blue-route
spec:
  from:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: ns-blue
  nextHops:
    static:
    - ip: "192.168.99.13"
EOF

# Create AdminPolicyBasedExternalRoute for ns-red
cat <<EOF | oc apply -f -
apiVersion: k8s.ovn.org/v1
kind: AdminPolicyBasedExternalRoute
metadata:
  name: ns-red-route
spec:
  from:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: ns-red
  nextHops:
    static:
    - ip: "192.168.99.14"
EOF
