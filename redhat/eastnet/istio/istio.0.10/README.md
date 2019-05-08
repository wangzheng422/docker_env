#

<https://github.com/Maistra/istio-operator/tree/maistra-0.10/deploy/examples>

```bash
oc new-project istio-operator
oc new-project istio-system
oc apply -n istio-operator -f servicemesh-operator.yaml

oc get cm -n istio-system istio -o jsonpath='{.data.mesh}' | grep disablePolicyChecks
oc edit cm -n istio-system istio

oc create -n istio-system -f istio-installation.yaml

oc update -n istio-system -f istio-installation.yaml

oc get controlplane/istio-installation -n istio-system --template='{{range .status.conditions}}{{printf "%s=%s, reason=%s, message=%s\n\n" .type .status .reason .message}}{{end}}'

# delete
oc get controlplanes -n istio-system
oc delete -n istio-system -f <name_of_custom_resource>

oc delete -n istio-operator -f servicemesh-operator.yaml
```