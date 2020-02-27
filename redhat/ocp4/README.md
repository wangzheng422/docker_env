```bash
oc get clusterversion

touch htpasswd
htpasswd -Bb htpasswd USER PASSWORD
oc create secret generic htpasswd --from-file=htpasswd -n openshift-config

oc whoami --show-console 
oc whoami --show-server
oc whoami --show-token

oc get secret htpasswd -n openshift-config -o jsonpath={.data.htpasswd} \
    | base64 -d >htpasswd
htpasswd -Bb htpasswd USER PASSWORD
oc patch secret htpasswd -n openshift-config \
    -p '{"data":{"htpasswd":"'$(base64 -w0 htpasswd)'"}}'
```

```yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
```
```bash
oc create configmap ldap-tls-ca -n openshift-config \
    --from-file=ca.crt=PATH_TO_LDAP_CA_FILE

oc create secret generic ldap-bind-password -n openshift-config \
    --from-literal=bindPassword=PASSWORD
```
```yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: OpenTLC LDAP
    challenge: true
    login: true
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id: ["dn"]
        email: ["mail"]
        name: ["cn"]
        preferredUsername: ["uid"]
      bindDN: "uid=admin,cn=users,cn=accounts,dc=shared,dc=example,dc=com"
      bindPassword:
        name: ldap-bind-password
      insecure: false
      ca:
        name: ldap-tls-ca
      url: "ldaps://ipa.example.com:636/cn=users,cn=accounts,dc=shared,dc=example,dc=com?uid?sub?(memberOf=cn=ocp-users,cn=groups,cn=accounts,dc=shared,dc=example,dc=com)"
```
```bash
export KUBECONFIG=OCP4_INSTALL_DIR/auth/kubeconfig
oc config use-context admin
oc whoami
oc get pods -n openshift-authentication
oc logs -n openshift-authentication oauth-openshift-8fcd5c679-f82qx
oc logs -n openshift-authentication-operator deployment/authentication-operator

oc get groups
oc adm groups new GROUP
oc adm groups add-users GROUP USER
oc adm groups remove-users GROUP USER
oc delete group GROUP

```
```yaml
kind: LDAPSyncConfig
apiVersion: v1
url: "ldap://ipa.shared.example.opentlc.com:389"
bindDN: "uid=admin,cn=users,cn=accounts,dc=shared,dc=example,dc=opentlc,dc=com"
bindPassword:
  file: /etc/secrets/bind_password
ca: /etc/config/ldap-ca.crt
insecure: false
rfc2307:
  groupsQuery:
    baseDN: "cn=groups,cn=accounts,dc=shared,dc=example,dc=opentlc,dc=com"
    scope: sub
    derefAliases: never
    filter: (!(objectClass=mepManagedEntry))
    pageSize: 0
    timeout: 0
  groupUIDAttribute: dn
  groupNameAttributes: [ cn ]
  groupMembershipAttributes: [ member ]
  usersQuery:
    baseDN: "cn=users,cn=accounts,dc=shared,dc=example,dc=opentlc,dc=com"
    scope: sub
    derefAliases: never
  userUIDAttribute: dn
  userNameAttributes: [ uid ]
```
```bash
oc get clusterrole
oc get role 
oc policy add-role-to-user CLUSTER_ROLE USER -n NAMESPACE
oc policy add-role-to-user ROLE USER -n NAMESPACE --role-namespace=NAMESPACE
oc policy add-role-to-group CLUSTER_ROLE GROUP -n NAMESPACE
oc policy add-role-to-group ROLE GROUP -n NAMESPACE --role-namespace=NAMESPACE
oc policy remove-role-from-user CLUSTER_ROLE USER -n NAMESPACE
oc policy remove-role-from-user ROLE USER -n NAMESPACE --role-namespace=NAMESPACE
oc policy remove-user USER -n NAMESPACE
oc policy remove-role-from-group CLUSTER_ROLE GROUP -n NAMESPACE
oc policy remove-role-from-group ROLE GROUP -n NAMESPACE --role-namespace=NAMESPACE
oc policy remove-user GROUP -n NAMESPACE
oc adm policy add-cluster-role-to-user CLUSTER_ROLE USER
oc adm policy add-cluster-role-to-group CLUSTER_ROLE GROUP
oc adm policy remove-cluster-role-from-user CLUSTER_ROLE USER
oc adm policy remove-cluster-role-from-group CLUSTER_ROLE GROUP

oc annotate clusterrolebinding self-provisioners rbac.authorization.kubernetes.io/autoupdate=false --overwrite
oc adm policy remove-cluster-role-from-group self-provisioner system:authenticated:oauth

oc auth can-i VERB KIND [-n NAMESPACE]
oc auth can-i patch namespaces
oc auth can-i get pods -n openshift-authentication
oc policy can-i --list

oc policy who-can VERB KIND
oc policy who-can get imagestreams -n openshift

oc get pods -n example-app-db \
    --as=: \
    --as-group=example-app-dev
oc auth can-i create projectrequests \
    --as=: \
    --as-group=system:authenticated \
    --as-group=system:authenticated:oauth

oc --user=admin get users
oc --config $HOME/cluster-$GUID/auth/kubeconfig get identities
oc --user=admin delete secret kubeadmin -n kube-system
oc --user=admin adm groups sync \
    --sync-config=groupsync.yaml \
    --whitelist=whitelist.txt
```
```json
{
  "spec": {
    "projectRequestMessage": "Please create projects using the portal http://portal.company.internal/provision or PaaS Support at paas-support@example.com"
  }
}
```
```bash
oc patch projects.config.openshift.io cluster --type=merge \
    -p "$(cat projects-config.patch.json)"

# sa
/run/secrets/kubernetes.io/serviceaccount/token

oc get secret --field-selector=type=kubernetes.io/service-account-token -n NAMESPACE
oc serviceaccount get-token SERVICE_ACCOUNT -n NAMESPACE
oc policy add-role-to-group system:image-puller -n myapp-build
      system:serviceaccounts:myapp-dev
oc create secret docker-registry SECRET_NAME -n NAMESPACE \
    --docker-username=USERNAME \
    --docker-password=PASSWORD \
    --docker-email=EMAIL
oc secrets link --for=pull SERVICE_ACCOUNT SECRET_NAME -n NAMESPACE

oc get pod -n NAMESPACE \
 -o jsonpath='{range .items[*]}{.metadata.name} {.spec.serviceAccountName}{"\n"}{end}'

TOKEN=$(oc serviceaccounts get-token operator -n app-operator)
oc --token=$TOKEN get deployment -n app-dev

oc expose service gitlab-ce --port 80

oc describe resourcequotas total-resources

oc create clusterresourcequota my-cluster-resource-quota --project-label-selector=org=myorg --hard=pods=10 --hard=secrets=20

oc adm create-bootstrap-project-template -o yaml > $HOME/project_request_template.yaml
oc create -f $HOME/project_request_template.yaml -n openshift-config
oc patch projects.config.openshift.io cluster -p '{"spec": {"projectRequestTemplate": {"name": "project-request"}}}' --type=merge


env TZ=Asia/Shanghai date

oc proxy 8001
curl localhost:8001/openapi/v2 | jq

```