```bash
# Download the latest AWS Command Line Interface
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip

# Install the AWS CLI into /bin/aws
./awscli-bundle/install -i /usr/local/aws -b /bin/aws

# Validate that the AWS CLI works
aws --version

OCP_VERSION=4.1.0
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux-${OCP_VERSION}.tar.gz
tar zxvf openshift-install-linux-${OCP_VERSION}.tar.gz -C /usr/bin
rm -f openshift-install-linux-${OCP_VERSION}.tar.gz /usr/bin/README.md
chmod +x /usr/bin/openshift-install

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz
tar zxvf openshift-client-linux-${OCP_VERSION}.tar.gz -C /usr/bin
rm -f openshift-client-linux-${OCP_VERSION}.tar.gz /usr/bin/README.md
chmod +x /usr/bin/oc

oc completion bash >/etc/bash_completion.d/openshift

export AWSKEY=<YOURACCESSKEY>
export AWSSECRETKEY=<YOURSECRETKEY>
export REGION=ap-southeast-1

mkdir $HOME/.aws
cat << EOF >>  $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF

aws sts get-caller-identity

# https://cloud.openshift.com/clusters/install

ssh-keygen -f ~/.ssh/cluster-${GUID}-key -N ''

openshift-install create cluster --dir $HOME/cluster-${GUID}
tail -f ${HOME}/cluster-${GUID}/.openshift_install.log

openshift-install destroy cluster --dir $HOME/cluster-${GUID}
rm -rf $HOME/.kube
rm -rf $HOME/cluster-${GUID}

oc get pod -A
oc get clusterversion
oc get route console -n openshift-console

aws ec2 describe-instances --region=ap-southeast-1 --output table
openshift-install graph

oc get machines -n openshift-machine-api
oc get machines -n openshift-machine-api -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{"\t"}{.spec.providerSpec.value.instanceType}{end}{"\n"}'
oc get machines -l machine.openshift.io/cluster-api-machine-type=master -n openshift-machine-api
oc get machines -l machine.openshift.io/cluster-api-machine-type=master -n openshift-machine-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.providerSpec.value.placement.region}{"\n"}{end}'
oc get machines -l machine.openshift.io/cluster-api-machine-type=master -n openshift-machine-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.providerSpec.value.placement.availabilityZone}{"\n"}{end}'
oc get machines -l machine.openshift.io/cluster-api-machine-type=worker -n openshift-machine-api

oc get machinesets -n openshift-machine-api
oc get machinesets -n openshift-machine-api -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{"\t"}{.spec.replicas}{end}{"\n"}'
oc patch machineset cluster-4495-m4ft8-worker-ap-southeast-1c --type='merge' --patch='{"spec": { "template": { "spec": { "providerSpec": { "value": { "instanceType": "m5.2xlarge"}}}}}}' -n openshift-machine-api
oc scale machineset cluster-4495-m4ft8-worker-ap-southeast-1c --replicas=0 -n openshift-machine-api
oc scale machineset cluster-4495-m4ft8-worker-ap-southeast-1c --replicas=1 -n openshift-machine-api

openshift-install destroy cluster --dir=${HOME}/cluster-${GUID}

# There is a custom resource default of type Tuned in project openshift-cluster-node-tuning-operator. 
```