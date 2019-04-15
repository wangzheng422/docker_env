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

oc create -f istio-installation-full.yaml -n istio-operator

oc delete -f istio-installation-full.yaml -n istio-operator

oc get pods -n istio-system -w

oc delete -n istio-operator installation istio-installation
oc process -f istio_product_operator_template.yaml | oc delete -f -
```

```json
ok: [127.0.0.1] => {
    "ansible_facts": {
        "openshift_istio_image_names": {
            "docker.io/istio/citadel:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/citadel:latest",
            "docker.io/istio/galley:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/galley:latest",
            "docker.io/istio/mixer:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/mixer:latest",
            "docker.io/istio/pilot:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/pilot:latest",
            "docker.io/istio/proxy:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/proxy:latest",
            "docker.io/istio/proxy_init:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/proxy-init:latest",
            "docker.io/istio/proxyv2:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/proxyv2:latest",
            "docker.io/istio/sidecar_injector:{{default_istio_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/sidecar-injector:latest",
            "jaegertracing/jaeger-agent:{{default_istio_jaeger_image_tag}}": "registry.paas.com/distributed-tracing-tech-preview/jaeger-agent:latest",
            "jaegertracing/jaeger-collector:{{default_istio_jaeger_image_tag}}": "registry.paas.com/distributed-tracing-tech-preview/jaeger-collector:latest",
            "jaegertracing/jaeger-query:{{default_istio_jaeger_image_tag}}": "registry.paas.com/distributed-tracing-tech-preview/jaeger-query:latest",
            "kiali/kiali:{{default_istio_kiali_image_tag}}": "registry.paas.com/openshift-istio-tech-preview/kiali:latest",
            "quay.io/3scale/3scale-istio-adapter:{{default_istio_threescale_image_tag}}": "openshift-istio-tech-preview/3scale-istio-adapter:0.4.1",
            "registry.centos.org/rhsyseng/elasticsearch:{{default_istio_elasticsearch_image_tag}}": "registry.paas.com/distributed-tracing-tech-preview/jaeger-elasticsearch:5.6.10"
        }
    },
    "changed": false
}
```