```bash
ssh -i ~/.ssh/id_rsa.redhat -tt  zhengwan-redhat.com@bastion.d4ed.blue.osp.opentlc.com tmux

# on base station
ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export OCP_RELEASE" line="export OCP_RELEASE=4.2.4"'

source $HOME/.bashrc

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz

sudo tar xzf openshift-client-linux-$OCP_RELEASE.tar.gz -C /usr/local/sbin/ oc kubectl

which oc

oc completion bash | sudo tee /etc/bash_completion.d/openshift > /dev/null

cat $HOME/.config/openstack/clouds.yaml

openstack server list -f json
openstack network list
openstack security group list

openstack subnet show $GUID-ocp-subnet -f json

ssh utilityvm.opentlc.internal

# on utility node
podman pull ubi7/ubi:7.7
podman run ubi7/ubi:7.7 cat /etc/os-release

sudo mkdir -p /opt/registry/{auth,certs,data}
sudo chown -R $USER /opt/registry
cd /opt/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 365 -out domain.crt
htpasswd -bBc /opt/registry/auth/htpasswd openshift redhat

podman run -d --name mirror-registry \
-p 5000:5000 --restart=always \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
-e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
docker.io/library/registry:2

curl -u openshift:redhat -k https://utilityvm.opentlc.internal:5000/v2/_catalog

curl -u openshift:redhat https://utilityvm.opentlc.internal:5000/v2/_catalog

sudo cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/

sudo update-ca-trust

curl -u openshift:redhat https://utilityvm.opentlc.internal:5000/v2/_catalog

podman login -u openshift -p redhat utilityvm.opentlc.internal:5000

podman tag registry.access.redhat.com/ubi7/ubi:7.7 utilityvm.opentlc.internal:5000/ubi7/ubi:7.7
podman push utilityvm.opentlc.internal:5000/ubi7/ubi:7.7

ls /opt/registry/data/docker/registry/v2/repositories

# on base station
curl -u openshift:redhat https://utilityvm.opentlc.internal:5000/v2/_catalog

sudo scp utilityvm.opentlc.internal:/opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
curl -u openshift:redhat https://utilityvm.opentlc.internal:5000/v2/_catalog

podman login -u openshift -p redhat --authfile $HOME/pullsecret_config.json utilityvm.opentlc.internal:5000

cat $HOME/pullsecret_config.json

jq -c --argjson var "$(jq .auths $HOME/pullsecret_config.json)" '.auths += $var' $HOME/ocp_pullsecret.json > merged_pullsecret.json

jq . merged_pullsecret.json

ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export LOCAL_REGISTRY" line="export LOCAL_REGISTRY=utilityvm.opentlc.internal:5000"'
ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export LOCAL_REPOSITORY" line="export LOCAL_REPOSITORY=ocp4/openshift4"'
ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export LOCAL_SECRET_JSON" line="export LOCAL_SECRET_JSON=/home/$USER/merged_pullsecret.json"'
ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export PRODUCT_REPO" line="export PRODUCT_REPO=openshift-release-dev"'
ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export RELEASE_NAME" line="export RELEASE_NAME=ocp-release"'
source $HOME/.bashrc

oc adm release mirror -a ${LOCAL_SECRET_JSON} \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}

podman pull --authfile $HOME/pullsecret_config.json utilityvm.opentlc.internal:5000/ocp4/openshift4:operator-lifecycle-manager

podman images

oc adm release info -a $HOME/merged_pullsecret.json "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}" | head -n 20

oc adm release info -a $HOME/merged_pullsecret.json "quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}" | head -n 20

oc adm release extract -a $HOME/merged_pullsecret.json --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}"

sudo mv openshift-install /usr/local/sbin/

openshift-install version

mkdir -p $HOME/openstack-upi
cd $HOME/openstack-upi

echo $API_FIP
echo $OPENSHIFT_DNS_ZONE
cat $HOME/merged_pullsecret.json

openshift-install create install-config --dir $HOME/openstack-upi
# edit install-config.yaml
```
```yaml
apiVersion: v1
baseDomain: blue.osp.opentlc.com
compute:
- hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 0 
controlPlane:
  hyperthreading: Enabled
  name: master
  platform:
    openstack:
      type: 4c16g30d 
  replicas: 3
metadata:
  creationTimestamp: null
  name: $GUID 
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineCIDR: 192.168.47.0/24 
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  openstack:
    cloud: $GUID-project
    computeFlavor: 4c16g30d 
    externalNetwork: external
    lbFloatingIP: 169.47.188.136 
    octaviaSupport: "1"
    region: ""
    trunkSupport: "1"
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K25zdGVwaGFuMWRma210bHJwdmlpZ3U2M2VuYTZxZ2R4bHJwOkJNTTZOOFI5MVRUOEFHSlJaVkVXMUJDVTFESVBTN0hISjhRR1E5UDI5WEFJNEVQSUw2TjNQN0o0R1ZaQVRYR0U=","email":"nstephan@redhat.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K25zdGVwaGFuMWRma210bHJwdmlpZ3U2M2VuYTZxZ2R4bHJwOkJNTTZOOFI5MVRUOEFHSlJaVkVXMUJDVTFESVBTN0hISjhRR1E5UDI5WEFJNEVQSUw2TjNQN0o0R1ZaQVRYR0U=","email":"nstephan@redhat.com"},"registry.connect.redhat.com":{"auth":"Nzc5NjE4MXx1aGMtMURma010THJQdmlJR3U2M2VuYTZRZ2R4THJwOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lKall6VmtZelJqWVRNd05UZzBZelkyWWpFeVkyTTVNMlUxWVRNNU0yRm1aU0o5LkFnWW00SjB5R1d4OHZ4bDNhcnVJSlFrTEFHb2NiVEQ4dkRNNUdIdEZpQU4zOGp4bXkyMlJLX004MGN2alZBa3FUWjJobEJqQ25kMGNYTVhxaXNFSlBxdzJOT3dlU0o1TGZxMEdlTUx6TmozSjNKVmxZWm9VMVR0OXNxa25vYWxWdTJEZ0xDalVPeHlOUVFTd0NuMTN3WFoxTl9DWnNXekxhU0tFZzc0VzUtR1YzTGVHZU92RV9EdTlld3NBMWt5MkYyMi01NlVES2w2Nmc4cU5waWlDRjVROXBfUXBZYzR0elpKczlrUHFlakVnNC1xOU0tVjBqajY4NGd3dk90TGYzcmV1VjJBLTFuS2ltRXNnVGhlbHloVllzSENaWVFveHNkNmFjZnVMMnhSa01KMXAyeVJBREhoNXJhUG51Nnh0Qjk1VmdhTVl4dkVURk43X2ctXzVqTWFGSnF6Ynk5Q2JxaHFRT1VNZnFFNHQzclltUGVIMkp0MTRMVWVkRHlDbzJXWUhzMlRjeGNYbUd1VFhmR2xvdmlYeXV0MDBfRndXM1N0MDhHLVlJX1htYXpWclRuVV92QVl2Tm5waWNPMzZVYUxoUXp2dUJ2ZnQtQUc5eEY1dDIwakZrZTNHZDhiNWxTN0tSUVRsRHNnQmRqbmkxQnZNYUJad2NQWEVieFd6dFJYNmdndXR1Z1lNNnJfc3E2ODJOZlRoeUdjLTE2RkZBNjdwWExWS0JyY1BlZzY4RWd6QV9HdC16MzlCWktSVTRwVnowbjRpX085WlV3MGlvbDlKVGJQcU5mZ1JRYWNUaEZzeHJWd3E3aVB4Zk5ZZW1NUFdQUG4xYjNpQzZDbnV0aC1zVWI5UWpPTDN2amNzV05qdGRGU2huSWVwTFVMOUlsWjB2YUR5clBB","email":"nstephan@redhat.com"},"registry.redhat.io":{"auth":"Nzc5NjE4MXx1aGMtMURma010THJQdmlJR3U2M2VuYTZRZ2R4THJwOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lKall6VmtZelJqWVRNd05UZzBZelkyWWpFeVkyTTVNMlUxWVRNNU0yRm1aU0o5LkFnWW00SjB5R1d4OHZ4bDNhcnVJSlFrTEFHb2NiVEQ4dkRNNUdIdEZpQU4zOGp4bXkyMlJLX004MGN2alZBa3FUWjJobEJqQ25kMGNYTVhxaXNFSlBxdzJOT3dlU0o1TGZxMEdlTUx6TmozSjNKVmxZWm9VMVR0OXNxa25vYWxWdTJEZ0xDalVPeHlOUVFTd0NuMTN3WFoxTl9DWnNXekxhU0tFZzc0VzUtR1YzTGVHZU92RV9EdTlld3NBMWt5MkYyMi01NlVES2w2Nmc4cU5waWlDRjVROXBfUXBZYzR0elpKczlrUHFlakVnNC1xOU0tVjBqajY4NGd3dk90TGYzcmV1VjJBLTFuS2ltRXNnVGhlbHloVllzSENaWVFveHNkNmFjZnVMMnhSa01KMXAyeVJBREhoNXJhUG51Nnh0Qjk1VmdhTVl4dkVURk43X2ctXzVqTWFGSnF6Ynk5Q2JxaHFRT1VNZnFFNHQzclltUGVIMkp0MTRMVWVkRHlDbzJXWUhzMlRjeGNYbUd1VFhmR2xvdmlYeXV0MDBfRndXM1N0MDhHLVlJX1htYXpWclRuVV92QVl2Tm5waWNPMzZVYUxoUXp2dUJ2ZnQtQUc5eEY1dDIwakZrZTNHZDhiNWxTN0tSUVRsRHNnQmRqbmkxQnZNYUJad2NQWEVieFd6dFJYNmdndXR1Z1lNNnJfc3E2ODJOZlRoeUdjLTE2RkZBNjdwWExWS0JyY1BlZzY4RWd6QV9HdC16MzlCWktSVTRwVnowbjRpX085WlV3MGlvbDlKVGJQcU5mZ1JRYWNUaEZzeHJWd3E3aVB4Zk5ZZW1NUFdQUG4xYjNpQzZDbnV0aC1zVWI5UWpPTDN2amNzV05qdGRGU2huSWVwTFVMOUlsWjB2YUR5clBB","email":"nstephan@redhat.com"},"utilityvm.opentlc.internal:5000":{"auth":"b3BlbnNoaWZ0OnJlZGhhdA=="}}}' 
sshKey: |
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKxG3JC+G/Euffe7TMw+jX6xgYOo6GeJdxYqpeoH4ZNTUPKYT3lr12Anockd7n74iLQ9vXo1LiMGMoDzPuE0xFTke1XFJXfryn5x+bnV/zS1O4+MKpqu4VlpacsApVNwPSx9+ynpXwAMhP3mZwmTkCAbtQnUNZtyftTw/OPaahKx6lP7GuCO92Z1hlgGT6DAukiW20Z/t2qh6M5JjSEhjPYP1+YKEWjjIDZyj1O24y6Ie+JUaljLO4RPzDrQ+WdbdRDfC1W5IdAHBFRZHZ7RhJstvuv/aURnxzwLkU3vYUJLGcB+Zj1kTprESndM9F/V3WoAO01LDJGWODsyNbnqQN nstephan@MacBook-Pro
imageContentSources: 
- mirrors:
  - utilityvm.opentlc.internal:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - utilityvm.opentlc.internal:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
additionalTrustBundle: | 
  -----BEGIN CERTIFICATE-----
  MIIGETCCA/mgAwIBAgIJAOaoQeFNmSo8MA0GCSqGSIb3DQEBCwUAMIGeMQswCQYD
  VQQGEwJVUzETMBEGA1UECAwKV2FzaGluZ3RvbjEQMA4GA1UEBwwHU2VhdHRsZTEQ
  MA4GA1UECgwHUmVkIEhhdDENMAsGA1UECwwER1BURTEjMCEGA1UEAwwadXRpbGl0
  eXZtLm9wZW50bGMuaW50ZXJuYWwxIjAgBgkqhkiG9w0BCQEWE25zdGVwaGFuQHJl
  ZGhhdC5jb20wHhcNMTkxMTAxMTc0NzM2WhcNMjAxMDMxMTc0NzM2WjCBnjELMAkG
  A1UEBhMCVVMxEzARBgNVBAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUx
  EDAOBgNVBAoMB1JlZCBIYXQxDTALBgNVBAsMBEdQVEUxIzAhBgNVBAMMGnV0aWxp
  dHl2bS5vcGVudGxjLmludGVybmFsMSIwIAYJKoZIhvcNAQkBFhNuc3RlcGhhbkBy
  ZWRoYXQuY29tMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvN+z6DZR
  sOlb+JIu2njv67XITHhCRF7ydVtXQEHmUypyeOrFjBswHRIKhFo/0+/Z5vhXhMwY
  j84xMAVyaFGnz4+WqJEGKfyUtXrTFyUfIFRQ6mKYwPsuFz7UhGNKQmSjSO3ujf6h
  /yAHN7IlxxlKGXKhDvX4gR/6OBbW03U/S+1rxQ4n8hoUNIvoDRKGnO1NMg7/Yl1t
  xv12blXdE04t2YsjJH/l5V69NLHGubcsAbfyDjazpET7dfBVbDEpdoSVnN92Zy62
  BAKm94ktqUrdpH33QumwBrkr/GLUo6gbO/qu9LB1NwNF8FQbde2dpg62FHIsQich
  7zrYnB+NjZEh4aMtC2fSzb8Y+yIu6TbfFIJpiVyM+2a4zO8o/YN4s7+JEttQPQCF
  cGw8unD/OyRKE4vkStX1122iAXD8dwPeBesclWY2+JzoI5tBRlIWcp+TIh2IgMkw
  ogY6NqAHroJj8gLZ31zM9c5qn+lTcZfdLeq66jhiy9VB4F6Oiw/mR7iGx35yZD5L
  9Lu5WF2ealtJpAjgOuilQfHsetUk02Uw8FXKyWtPQkF92cIwDNwXXrBmNchQGTAx
  JHKgj6bkwPYjC9OIbyIqqsTR8mndZbJRkA53xxt4QHXXwV5hy0twrGCq8inGTDcm
  Pfs+iXf1oDa+Xv8yHS8yC2BIxdyON9eEGQUCAwEAAaNQME4wHQYDVR0OBBYEFDqh
  6L/oiKdboNjxRpGyobhhgAz1MB8GA1UdIwQYMBaAFDqh6L/oiKdboNjxRpGyobhh
  gAz1MAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIBAJ419b+bIAQa/khx
  ueS3kguuCgN5neAdpbuzqvKQsEuDktpLdsypQo2pPuU/55iN04/aXSxa4tv9TQSf
  y2NM2JasAn0zwKvVeZdKqEM1WTTecbYCBKO/r/7SvWcH6Ze93Ot0/Ah73L70SANl
  Yj70/+w8KsnAFrDretiRJvLKimn3li0vRMygMfbm+P0cz1P/yb8HsoqffIZekS6X
  fyYhzo6caIerPoX6TzzP6xHAPKEWV4uxwqP4LJoGq/9Z5gsrkoMuGjnki/E/GYnm
  PNxXDGrtYR02Q2dxL2hDMvOyT6o3ydjHX3LpKjD4VIRCkrRRRIUxewuu39AJ9Sxc
  J2BRBoAMI9kPhE6ooeSrcxGLFDRjugBsGXn6xpTx1NrCPeePktIpHbIhj2BUVB82
  bxOA1lVL4aBqoGCMn7iz97AWFrW+XSFI4A0EgIsVTdyxVxUKUpb2jGryGHGd/4cq
  ZJS8n2WIQhdqxCsGrUBzJFG9IntCRGgSE+pltOutlVzq7I4epS9oQOrSVW0RcDTP
  TgWRkKTC2QY5wi9VMjQFaimzMzKYAiBrW6Nu0MaCzu3nFR/DnXyze0b+UzWDgfkl
  tpRngWMSJJo/2REkqJh/buKMrXRDPGooKoDCmNXG5NNc5jBMJM/4wkZ5jhoivAer
  VY/aiwI+Y9bIG6x7fXAi1P85pVuF
  -----END CERTIFICATE-----
```
```bash
mkdir -p $HOME/backup
cp $HOME/openstack-upi/install-config.yaml $HOME/backup/

openshift-install create manifests --dir $HOME/openstack-upi

ansible localhost -m lineinfile -a 'path="$HOME/openstack-upi/manifests/cluster-scheduler-02-config.yml" regexp="^  mastersSchedulable" line="  mastersSchedulable: false"'

cat $HOME/openstack-upi/manifests/cluster-scheduler-02-config.yml

# apiVersion: config.openshift.io/v1
# kind: Scheduler
# metadata:
#   creationTimestamp: null
#   name: cluster
# spec:
#   mastersSchedulable: false
#   policy:
#     name: ""
rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml

ansible localhost -m lineinfile -a "path=$HOME/.bashrc regexp=\"^export INFRA_ID\" line=\"export INFRA_ID=$(jq -r .infraID $HOME/openstack-upi/metadata.json)\""
source $HOME/.bashrc

cd $HOME/openstack-upi
python3 $HOME/resources/update_ignition.py

jq '.storage.files | map(select(.path=="/etc/dhcp/dhclient.conf", .path=="/etc/NetworkManager/conf.d/dhcp-client.conf", .path=="/etc/dhcp/dhclient.conf"))' bootstrap.ign

for index in $(seq 0 2); do
    MASTER_HOSTNAME="$INFRA_ID-master-$index\n"
    python3 -c "import base64, json, sys;
ignition = json.load(sys.stdin);
files = ignition['storage'].get('files', []);
files.append({'path': '/etc/hostname', 'mode': 420, 'contents': {'source': 'data:text/plain;charset=utf-8;base64,' + base64.standard_b64encode(b'$MASTER_HOSTNAME').decode().strip(), 'verification': {}}, 'filesystem': 'root'});
ignition['storage']['files'] = files;
json.dump(ignition, sys.stdout)" <master.ign >"$INFRA_ID-master-$index-ignition.json"
done

scp bootstrap.ign utilityvm.opentlc.internal:

ssh utilityvm.opentlc.internal sudo mv bootstrap.ign /var/www/html/
ssh utilityvm.opentlc.internal sudo restorecon /var/www/html/bootstrap.ign

cat << EOF > $HOME/openstack-upi/$INFRA_ID-bootstrap-ignition.json
{
  "ignition": {
    "config": {
      "append": [
        {
          "source": "http://utilityvm.opentlc.internal/bootstrap.ign",
          "verification": {}
        }
      ]
    },
    "security": {},
    "timeouts": {},
    "version": "2.2.0"
  },
  "networkd": {},
  "passwd": {},
  "storage": {},
  "systemd": {}
}
EOF

openstack port create --network "$GUID-ocp-network" --security-group "$GUID-master_sg" --fixed-ip "subnet=$GUID-ocp-subnet,ip-address=192.168.47.5" --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-api-port" -f json

openstack port create --network "$GUID-ocp-network" --security-group "$GUID-worker_sg" --fixed-ip "subnet=$GUID-ocp-subnet,ip-address=192.168.47.7" --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-ingress-port"

openstack floating ip set --port "$INFRA_ID-api-port" $API_FIP
openstack floating ip set --port "$INFRA_ID-ingress-port" $INGRESS_FIP

openstack floating ip list -c ID -c "Floating IP Address" -c "Fixed IP Address"

openstack port create --network "$GUID-ocp-network" --security-group "$GUID-master_sg" --allowed-address ip-address=192.168.47.5 --allowed-address ip-address=192.168.47.6 --allowed-address ip-address=192.168.47.7 --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-bootstrap-port"

openstack server create --image rhcos-ocp42 --flavor 4c16g30d --user-data "$HOME/openstack-upi/$INFRA_ID-bootstrap-ignition.json" --port "$INFRA_ID-bootstrap-port" --wait --property openshiftClusterID="$INFRA_ID" "$INFRA_ID-bootstrap"

ssh -i $HOME/.ssh/${GUID}key.pem core@$INFRA_ID-bootstrap.opentlc.internal
# journalctl -b -f -u bootkube.service
# journalctl -u release-image.service
# podman image ls
# cat /etc/containers/registries.conf

openstack server list -f json

for index in $(seq 0 2); do
    openstack port create --network "$GUID-ocp-network" --security-group "$GUID-master_sg" --allowed-address ip-address=192.168.47.5 --allowed-address ip-address=192.168.47.6 --allowed-address ip-address=192.168.47.7 --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-master-port-$index"
done

for index in $(seq 0 2); do
    openstack server create --boot-from-volume 30 --image rhcos-ocp42 --flavor 4c16g30d --user-data "$HOME/openstack-upi/$INFRA_ID-master-$index-ignition.json" --port "$INFRA_ID-master-port-$index" --property openshiftClusterID="$INFRA_ID" "$INFRA_ID-master-$index"
done

jq .ignition.config $HOME/openstack-upi/$INFRA_ID-master-0-ignition.json

openshift-install wait-for bootstrap-complete --dir $HOME/openstack-upi

openstack server delete "$INFRA_ID-bootstrap"
openstack port delete "$INFRA_ID-bootstrap-port"

ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export KUBECONFIG" line="export KUBECONFIG=$HOME/openstack-upi/auth/kubeconfig"'
source $HOME/.bashrc

oc get clusterversion
oc get clusteroperators

for index in $(seq 0 1); do
    openstack port create --network "$GUID-ocp-network" --security-group "$GUID-worker_sg" --allowed-address ip-address=192.168.47.5 --allowed-address ip-address=192.168.47.6 --allowed-address ip-address=192.168.47.7 --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-worker-port-$index"
done

for index in $(seq 0 1); do
    openstack server create --image rhcos-ocp42 --flavor 4c8g30d --user-data "$HOME/openstack-upi/worker.ign" --port "$INFRA_ID-worker-port-$index" --property openshiftClusterID="$INFRA_ID" "$INFRA_ID-worker-$index"
done

jq .ignition.config $HOME/openstack-upi/worker.ign

watch -n 10 oc get csr

oc describe csr csr-9rs74

oc adm certificate approve csr-88jp8

oc get clusterversion

oc get clusteroperators

openshift-install wait-for install-complete --dir $HOME/openstack-upi
# INFO Waiting up to 30m0s for the cluster at https://api.d4ed.blue.osp.opentlc.com:6443 to initialize...
# INFO Waiting up to 10m0s for the openshift-console route to be created...
# INFO Install complete!
# INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/zhengwan-redhat.com/openstack-upi/auth/kubeconfig'
# INFO Access the OpenShift web-console here: https://console-openshift-console.apps.d4ed.blue.osp.opentlc.com
# INFO Login to the console with user: kubeadmin, password: 

```
day 2
```bash
oc explain MachineSet.spec --recursive=true

oc get nodes

oc describe node d4ed-86v9t-worker-0

oc get machines -n openshift-machine-api

oc get machineset -n openshift-machine-api

oc get machinesets d4ed-86v9t-worker -o yaml -n openshift-machine-api

oc get machineset -n openshift-machine-api

oc scale machineset d4ed-86v9t-worker --replicas=1 -n openshift-machine-api

oc get machineset -n openshift-machine-api

oc get machine -n openshift-machine-api

oc describe machine d4ed-86v9t-worker-8xpmf -n openshift-machine-api

oc get pods -n openshift-machine-api

oc get pod machine-api-controllers-66988fdb78-r2m5p -o json -n openshift-machine-api | jq -r .spec.containers[].name

oc logs machine-api-controllers-66988fdb78-r2m5p -c machine-controller -n openshift-machine-api | grep -i worker

oc scale machineset d4ed-86v9t-worker --replicas=0 -n openshift-machine-api

oc get machines -n openshift-machine-api

oc get machineset d4ed-86v9t-worker -n openshift-machine-api -o yaml

cat << EOF > ~/machine.yaml
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: d4ed-86v9t
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
  name: general-purpose-1a
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: d4ed-86v9t
      machine.openshift.io/cluster-api-machineset: general-purpose-1a
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: d4ed-86v9t
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: general-purpose-1a
    spec:
      metadata:
        labels:
          failure-domain.beta.kubernetes.io/region: "east"
          failure-domain.beta.kubernetes.io/zone: "1a"
          node-role.kubernetes.io/general-use: ""
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: 4c12g30d
          image: rhcos-ocp42
          kind: OpenstackProviderSpec
          networks:
          - filter: {}
            subnets:
            - filter:
                name: ded1-ocp-subnet
          securityGroups:
          - filter: {}
            name: ded1-worker_sg
          serverMetadata:
            Name: d4ed-86v9t-worker
            openshiftClusterID: d4ed-86v9t
          tags:
          - openshiftClusterID=d4ed-86v9t
          trunk: true
          userDataSecret:
            name: worker-user-data
EOF

for i in 1a 1b
do
ansible localhost -m template -a "src='$HOME/resources/general-ms.yaml.j2' dest='$HOME/worker-ms-$i.yaml'" -e msid=$i
done

oc create -f worker-ms-1a.yaml -n openshift-machine-api
oc create -f worker-ms-1b.yaml -n openshift-machine-api
oc get machineset -n openshift-machine-api

oc scale machineset general-purpose-1a --replicas=1 -n openshift-machine-api
oc scale machineset general-purpose-1b --replicas=1 -n openshift-machine-api

oc get machines -n openshift-machine-api

oc get nodes

oc adm cordon d4ed-86v9t-worker-0
oc adm drain d4ed-86v9t-worker-0 --ignore-daemonsets --delete-local-data --force=true

oc adm cordon d4ed-86v9t-worker-1
oc adm drain d4ed-86v9t-worker-1 --ignore-daemonsets --delete-local-data --force=true

oc get nodes

oc delete node d4ed-86v9t-worker-0 d4ed-86v9t-worker-1

openstack server list --name $INFRA_ID-worker -f value -c ID | xargs openstack server delete

openstack server list -c ID -c Name -c Status

oc get machineset general-purpose-1a -o yaml -n openshift-machine-api > infra-ms.yaml

cat << EOF >~/infra-1a.yaml
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: d4ed-86v9t
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
  name: infra-1a
  namespace: openshift-machine-api
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: d4ed-86v9t
      machine.openshift.io/cluster-api-machineset: infra-1a
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: d4ed-86v9t
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: infra-1a
    spec:
      metadata:
        labels:
          node-role.kubernetes.io/infra: ""
          failure-domain.beta.kubernetes.io/region: east
          failure-domain.beta.kubernetes.io/zone: 1a
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: 4c12g30d
          image: rhcos-ocp42
          kind: OpenstackProviderSpec
          metadata:
            creationTimestamp: null
          networks:
          - filter: {}
            subnets:
            - filter:
                name: d4ed-ocp-subnet
          securityGroups:
          - filter: {}
            name: d4ed-worker_sg
          serverMetadata:
            Name: d4ed-86v9t-worker
            openshiftClusterID: d4ed-86v9t
          tags:
          - openshiftClusterID=d4ed-86v9t
          trunk: true
          userDataSecret:
            name: worker-user-data
EOF

oc create -f infra-1a.yaml

oc get machines -n openshift-machine-api -w

oc get nodes -w

oc explain clusterautoscaler.spec --recursive=true

oc explain clusterautoscaler.spec.balanceSimilarNodeGroups

oc project openshift-machine-api

oc get machineset

echo "
apiVersion: autoscaling.openshift.io/v1beta1
kind: MachineAutoscaler
metadata:
  name: ma-general-purpose-1a
  namespace: openshift-machine-api
spec:
  minReplicas: 1
  maxReplicas: 4
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: general-purpose-1a" | oc create -f - -n openshift-machine-api

echo "
apiVersion: autoscaling.openshift.io/v1beta1
kind: MachineAutoscaler
metadata:
  name: ma-general-purpose-1b
  namespace: openshift-machine-api
spec:
  minReplicas: 1
  maxReplicas: 4
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: general-purpose-1b" | oc create -f - -n openshift-machine-api

oc get machineautoscaler

echo "
apiVersion: autoscaling.openshift.io/v1
kind: ClusterAutoscaler
metadata:
  name: default
spec:
  balanceSimilarNodeGroups: true
  podPriorityThreshold: -10
  resourceLimits:
    maxNodesTotal: 12
    cores:
      min: 24
      max: 48
    memory:
      min: 84
      max: 156
  scaleDown:
    enabled: true
    delayAfterAdd: 5m
    delayAfterDelete: 5m
    delayAfterFailure: 5m
    unneededTime: 60s" | oc create -f -

oc describe clusterautoscaler default

oc get machinesets -o yaml | grep annotations -A 3

oc get pods

oc logs -f cluster-autoscaler-default-66cdb74d49-gmn6m -n openshift-machine-api

echo '
apiVersion: batch/v1
kind: Job
metadata:
  generateName: work-queue-
spec:
  template:
    spec:
      containers:
      - name: work
        image: busybox
        command: ["sleep",  "300"]
        resources:
          requests:
            memory: 500Mi
            cpu: 300m
      restartPolicy: Never
      nodeSelector:
        node-role.kubernetes.io/general-use: ""
  parallelism: 50
  completions: 50' | oc create -f - -n work-queue

oc edit clusterautoscaler default

oc delete machineautoscaler ma-general-purpose-1a ma-general-purpose-1b -n openshift-machine-api



```