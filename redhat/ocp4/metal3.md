```bash

####################################
## workstation
ssh -i ~/.ssh/id_rsa.redhat -tt zhengwan-redhat.com@workstation-4794.rhpds.opentlc.com tmux
sudo -i
su - cloud-user

ssh kni@provisioner

######################################
## provisioner
mkdir -p ~/go/src/github.com/openshift/
git clone https://github.com/rdoxenham/installer -b rhte \
    ~/go/src/github.com/openshift/installer
git clone https://github.com/rdoxenham/dev-scripts -b rhte

cd dev-scripts/
cat > config_kni.sh << EOF
export PULL_SECRET='{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K3JobnNzb3JveGVuaGFtMWhyemtlb28yd2dqOHpkeHRoZGVucGUzcG56Ok5FUThJOFFMWUk3VEdNSThHQVlKRzBVU0pPOE9BTlQ3NFJHUUpETFBBRUY2WlpQQzBBMjBEOENOWTNQQTc1SEI=","email":"roxenham@redhat.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K3JobnNzb3JveGVuaGFtMWhyemtlb28yd2dqOHpkeHRoZGVucGUzcG56Ok5FUThJOFFMWUk3VEdNSThHQVlKRzBVU0pPOE9BTlQ3NFJHUUpETFBBRUY2WlpQQzBBMjBEOENOWTNQQTc1SEI=","email":"roxenham@redhat.com"},"registry.connect.redhat.com":{"auth":"NTM5NTcwMnx1aGMtMUhSemtFT28yV2dKOHpEeFRoRGVuUEUzcG5aOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lKak5tWXdaRGczT1RGaU16TTBNakk0T0RWbFltTXhZVEJoT1RsalpEazFOaUo5LkFqYVNGNFpjZ21tVy1pU0JIVHA5dDFER3E2aE9fMnE5YXdiN2NKOFFuWWNCVnNQVHA2WDdibG94cmpYZGZfU2psamJqZHZqOVJfYjkzcE1FSUdVaW5aeGdRN2lhSWk0OW5VMmd3LVIxcUFsTklzT1JwVWpVRU05T1R5VUNrMllYYmViRnBTTDZpNFprMjZHdktSVnA5N3F2MFpKTG9pUl9oS08xbi1LU1BTWmE2SGE5SFhkQXR1LWthd0RacDZ2a0daanRGd21jZzBpbk1JWUhRRjhsSUh0Tm5XR2JMS2hxQVpQekk4Q3pnWXI3SGVrTHJRa25Dbmo2bTJoRG1wS3ZQMnpNejJOYS11QVVvNzhYUndDQ09ibjNuMTlEVWNheUZ2Nm5NVGQ4UHNVWTZJeDFQSEY2Qm5hendnNHRJZkJZN19IQjQzTUtoMnZQQXRScEJSdmtNNXZpaWpHemdBVjV3d0hyNlRQQS1RUXpoNDlpbERxdjFTeVJZTllqUUUycjNiSmpHTFR2dmdwcEdfVGVqVEVZTGI0MGVDallJRHdMZzVfY1I1aHlzUnRtSElKZGVFcmduV3RQQXJhekNrdlVGSTQ0T2Q2SHo4LWlBbTRna3lwRGRHZno5SE5MbW00enFYNURXY1VrLVBSS3pTS0tCVlRrcm1QRll6cG56WjNNZE9kT2JFZjlncFhWUWxWRU9QN0lFdTIxWHAxdXNNNVloSjRTSjQwYTM0Ui1ESWd2ZllkZVExTDdmaFQ3dUlUcjhVbEFwTVVBMG5hQnk0MzczaVZWVldHUUh5SUVMU3JDeXVXWGtvd0FXaFlYenNjSGJycDIxaG81eDJWNDNyenBqNENmUHhoUTVDNkJJYmdtcC12eGxITWlZX3BEbFFZangxMXl4S1RtSndF","email":"roxenham@redhat.com"},"registry.redhat.io":{"auth":"NTM5NTcwMnx1aGMtMUhSemtFT28yV2dKOHpEeFRoRGVuUEUzcG5aOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lKak5tWXdaRGczT1RGaU16TTBNakk0T0RWbFltTXhZVEJoT1RsalpEazFOaUo5LkFqYVNGNFpjZ21tVy1pU0JIVHA5dDFER3E2aE9fMnE5YXdiN2NKOFFuWWNCVnNQVHA2WDdibG94cmpYZGZfU2psamJqZHZqOVJfYjkzcE1FSUdVaW5aeGdRN2lhSWk0OW5VMmd3LVIxcUFsTklzT1JwVWpVRU05T1R5VUNrMllYYmViRnBTTDZpNFprMjZHdktSVnA5N3F2MFpKTG9pUl9oS08xbi1LU1BTWmE2SGE5SFhkQXR1LWthd0RacDZ2a0daanRGd21jZzBpbk1JWUhRRjhsSUh0Tm5XR2JMS2hxQVpQekk4Q3pnWXI3SGVrTHJRa25Dbmo2bTJoRG1wS3ZQMnpNejJOYS11QVVvNzhYUndDQ09ibjNuMTlEVWNheUZ2Nm5NVGQ4UHNVWTZJeDFQSEY2Qm5hendnNHRJZkJZN19IQjQzTUtoMnZQQXRScEJSdmtNNXZpaWpHemdBVjV3d0hyNlRQQS1RUXpoNDlpbERxdjFTeVJZTllqUUUycjNiSmpHTFR2dmdwcEdfVGVqVEVZTGI0MGVDallJRHdMZzVfY1I1aHlzUnRtSElKZGVFcmduV3RQQXJhekNrdlVGSTQ0T2Q2SHo4LWlBbTRna3lwRGRHZno5SE5MbW00enFYNURXY1VrLVBSS3pTS0tCVlRrcm1QRll6cG56WjNNZE9kT2JFZjlncFhWUWxWRU9QN0lFdTIxWHAxdXNNNVloSjRTSjQwYTM0Ui1ESWd2ZllkZVExTDdmaFQ3dUlUcjhVbEFwTVVBMG5hQnk0MzczaVZWVldHUUh5SUVMU3JDeXVXWGtvd0FXaFlYenNjSGJycDIxaG81eDJWNDNyenBqNENmUHhoUTVDNkJJYmdtcC12eGxITWlZX3BEbFFZangxMXl4S1RtSndF","email":"roxenham@redhat.com"},"registry.svc.ci.openshift.org": { "auth": "c3lzdGVtLXNlcnZpY2VhY2NvdW50LWtuaS1kZWZhdWx0OmV5SmhiR2NpT2lKU1V6STFOaUlzSW10cFpDSTZJaUo5LmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUpyYm1raUxDSnJkV0psY201bGRHVnpMbWx2TDNObGNuWnBZMlZoWTJOdmRXNTBMM05sWTNKbGRDNXVZVzFsSWpvaVpHVm1ZWFZzZEMxMGIydGxiaTAxZEdkbU55SXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMbTVoYldVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WlhKMmFXTmxMV0ZqWTI5MWJuUXVkV2xrSWpvaVlqZzNNRGt4WmpZdE5qRXlNeTB4TVdVNUxXRTJNVGt0TkRJd01UQmhPR1V3TURBeUlpd2ljM1ZpSWpvaWMzbHpkR1Z0T25ObGNuWnBZMlZoWTJOdmRXNTBPbXR1YVRwa1pXWmhkV3gwSW4wLm51VGR0RlczRENHcFpvT0pCbU45VjQwWG1wbmlZRE9tUnI2Z05vNGVwRVBrb1lDXzk1YmhWX0ttYjhoTnprOTNVTGtDNnJXNTVjTXFQMVM4RHh3QWw0RUxRZ2NFZXIyalBJLXZBNGUzdlZ5cHNLbS1XSkFxcWo2OGhNN0Z4ekMzRGgxY19lN19EQkJLOWtxZmcyRzZiNTJXQmI2RUhsODg2Q2Nza3JBVm1fbmprNS14ay1Ma1hSM3lXNW5JeXlZdXhNVGg1LUNMd3lQQy1yLVIzeklzdnlWelNPVTgyeUJaaE1tUmc3enUtOWlydThENHdqRFJQclhiSm1FV3lBM1FIUlJ2VTJuci01MTFEeEhEbWhtNW14YU0tSFA4emk3SU8zVEU5SU55S3BqTmo5eTIwNmtFN0NNSVNMWmRWWFl3MkpIQ1BmSmJQMHNJY3V0dnFvOTdGdw=="}}}'
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="registry.svc.ci.openshift.org/kni/release:4.2.0-0.ci-2019-08-21-102306-rhte.0"
export KNI_INSTALL_FROM_GIT=true
NODES_PLATFORM="baremetal"
NODES_FILE="ironic_hosts.json"
NUM_WORKERS=0
NUM_MASTERS=3
PRO_IF=eth1
INT_IF=eth2
MANAGE_BR_BRIDGE=n
ADDN_DNS=192.0.2.254
CLUSTER_NAME=kni
DNS_VIP=192.168.111.252
BASE_DOMAIN=example.com
EXTERNAL_SUBNET="192.168.111.0/24"
NTP_SERVERS="0.uk.pool.ntp.org;1.uk.pool.ntp.org;2.uk.pool.ntp.org;3.uk.pool.ntp.org"
EOF

cat > ironic_hosts.json << EOF
{
  "nodes": [
      {
      "name": "openshift-master-0",
      "driver": "ipmi",
      "resource_class": "baremetal",
      "driver_info": {
        "ipmi_username": "admin",
        "ipmi_password": "redhat",
        "ipmi_address": "192.0.2.221",
        "deploy_kernel": "http://172.22.0.2/images/ironic-python-agent.kernel",
        "deploy_ramdisk": "http://172.22.0.2/images/ironic-python-agent.initramfs"
      },
      "ports": [{
        "address": "2c:c2:60:01:02:02",
        "pxe_enabled": true
      }],
      "properties": {
        "local_gb": "50",
        "cpu_arch": "x86_64"
      }
    },
     {
      "name": "openshift-master-1",
      "driver": "ipmi",
      "resource_class": "baremetal",
      "driver_info": {
        "ipmi_username": "admin",
        "ipmi_password": "redhat",
        "ipmi_address": "192.0.2.222",
        "deploy_kernel": "http://172.22.0.2/images/ironic-python-agent.kernel",
        "deploy_ramdisk": "http://172.22.0.2/images/ironic-python-agent.initramfs"
      },
      "ports": [{
        "address": "2c:c2:60:01:02:03",
        "pxe_enabled": true
      }],
      "properties": {
        "local_gb": "50",
        "cpu_arch": "x86_64"
      }
    },
    {
      "name": "openshift-master-2",
      "driver": "ipmi",
      "resource_class": "baremetal",
      "driver_info": {
        "ipmi_username": "admin",
        "ipmi_password": "redhat",
        "ipmi_address": "192.0.2.223",
        "deploy_kernel": "http://172.22.0.2/images/ironic-python-agent.kernel",
        "deploy_ramdisk": "http://172.22.0.2/images/ironic-python-agent.initramfs"
      },
      "ports": [{
        "address": "2c:c2:60:01:02:04",
        "pxe_enabled": true
      }],
      "properties": {
        "local_gb": "50",
        "cpu_arch": "x86_64"
      }
    }
 ]
}
EOF

time ./01_install_requirements.sh
```