
```bash
# 192.168.40.120
# registry.access.redhat.com/openshift3/node:v3.11
# change image to registry.sigma.cmri
oc edit ds ovs-vsctl-amd64

docker pull registry.redhat.io/openshift3/node:v3.11.98
docker tag registry.redhat.io/openshift3/node:v3.11.98 registry.sigma.cmri/openshift3/node:v3.11.98
docker push registry.sigma.cmri/openshift3/node:v3.11.98
docker tag registry.sigma.cmri/openshift3/node:v3.11.98  registry.sigma.cmri/openshift3/node:v3.11
docker push registry.sigma.cmri/openshift3/node:v3.11


docker load -i nttmec_cpu.tar.gz
docker tag da1f6a4a3d15ebc67fe098a9f15cd207de306703584a08da36b6aa527e87cce4 registry.sigma.cmri/test/nttmec_cpu
docker push registry.sigma.cmri/test/nttmec_cpu

docker load -i nttmec_gpu.tar.gz
docker tag 72719d7ba3f5ceaac97e84c146e96b690cfc4d2f24bce577265fc60085aa9d8f registry.sigma.cmri/test/nttmec_gpu
docker push registry.sigma.cmri/test/nttmec_gpu

oc apply -f demo.yaml

oc create serviceaccount mysvcacct -n nvidia
oc adm policy add-scc-to-user privileged system:serviceaccount:myproject:mysvcacct -n nvidia
oc adm policy remove-scc-from-user privileged system:serviceaccount:myproject:mysvcacct -n nvidia
oc adm policy add-scc-to-user privileged -z mysvcacct -n nvidia
oc adm policy remove-scc-from-user privileged -z mysvcacct -n nvidia
oc adm policy add-scc-to-user anyuid -z mysvcacct -n nvidia
oc adm policy remove-scc-from-user anyuid -z mysvcacct -n nvidia

docker run --rm -it registry.sigma.cmri/test/nttmec_gpu bash
```