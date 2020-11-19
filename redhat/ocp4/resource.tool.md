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

uuidgen -t
# To generate the current time as Unix time:
date +%s%N | cut -b1-13


pigz -dc registry.tgz | tar xf -

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-making-usb-media
diskutil list
diskutil unmountDisk /dev/disk2
sudo dd if=./rhel-server-7.6-x86_64-dvd.iso of=/dev/rdisk2 bs=10m


# https://unix.stackexchange.com/questions/181067/how-to-read-dmesg-from-previous-session-dmesg-0
# Options:
# -k (dmesg)
# -b < boot_number > (How many reboots ago 0, -1, -2, etc.)
# -o short-precise (dmesg -T)
# -p priority Filter by priority output (4 to filter out notice and info).
# Current boot : journalctl -o short-precise -k
# Last boot : journalctl -o short-precise -k -b -1
# Two boots prior : journalctl -o short-precise -k -b -2
journalctl -o short-precise -k
journalctl -o short-precise -k -b -1
journalctl --list-boot

# https://access.redhat.com/solutions/696893
sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
systemctl restart systemd-journald.service

spec:
  unsupportedConfigOverrides:
    servicesNodePortRange: <range-low>-<range-high>
    
# The original worker.ign has a certificate that expires after 24 hours.  To get the current data to use for worker.ign use this command:
oc extract -n openshift-machine-api secret/worker-user-data --keys=userData --to=-


oc get pod -n openshift-controller-manager
oc get pod -n openshift-controller-manager-operator
oc get pod -n openshift-kube-controller-manager
oc get pod -n openshift-kube-controller-manager-operator

oc delete pod --all -n openshift-controller-manager
oc delete pod --all -n openshift-controller-manager-operator
oc delete pod --all -n openshift-kube-controller-manager
oc delete pod --all -n openshift-kube-controller-manager-operator

oc get pod -n openshift-kube-scheduler
oc get pod -n openshift-kube-scheduler-operator

POD_NAME=$(oc get pod -n openshift-kube-scheduler-operator -o json | jq -r .items[0].metadata.name)
oc logs $POD_NAME -n openshift-kube-scheduler-operator

oc delete pod --all -n openshift-kube-scheduler-operator
oc delete pod --all -n openshift-kube-scheduler

oc get pod -n openshift-apiserver
oc get pod -n openshift-apiserver-operator

oc logs openshift-apiserver-operator-f79557665-8gvnm -n openshift-apiserver-operator

IMG=registry.redhat.io/openshift-serverless-1/client-kn-rhel8@sha256:47bd682ee37236edbbf45ba584cf25a69be13fbf3116d0a139b48ab916eb984d
echo ${IMG##*/}
SIMG=${IMG##*/}
echo ${SIMG%@*}
sed 's/=.*//g' mapping.txt > test

```