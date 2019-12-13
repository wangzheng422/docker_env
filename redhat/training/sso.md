https://github.com/jbossdemocentral/sso-kubernetes-workshop
```bash

oc login https://master.sso-3e67.open.redhat.com/ --insecure-skip-tls-verify=true -u evals07 -p Abt7MjWMb8v4ECS
oc new-project evals07-sso-kubernetes-workshop
oc policy add-role-to-user view admin -n $(oc project -q)
oc policy add-role-to-user view -n $(oc project -q) -z default
oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default

oc get templates -n openshift -o name | grep -o 'sso73.\+'

# https://sso-evals07-sso-kubernetes-workshop.apps.sso-3e67.open.redhat.com/auth/realms/demojs/account
# https://sso-evals07-sso-kubernetes-workshop.apps.sso-3e67.open.redhat.com/auth/realms/demojs/protocol/openid-connect/auth?client_id=account&redirect_uri=https%3A%2F%2Fsso-evals07-sso-kubernetes-workshop.apps.sso-3e67.open.redhat.com%2Fauth%2Frealms%2Fdemojs%2Faccount%2Flogin-redirect&state=0%2F27f3b906-b78d-4ff3-b4b7-6822b1af3fa8&response_type=code&scope=openid

# https://sso-evals07-sso-kubernetes-workshop.apps.sso-3e67.open.redhat.com/

oc new-build --name js-console --binary --strategy source --image-stream httpd
oc start-build js-console --from-dir . --follow
oc new-app --image-stream=js-console:latest
oc expose svc/js-console

#build individual projects
cd magic-link
mvn clean compile package

cd ../themes
mvn clean compile package

# copy the jar files
cd ../sso-custom/stream
cp ../../magic-link/target/magic-link.jar deployments/
cp ../../themes/target/themes.jar deployments/

# Create a new project
oc new-project evals07-sso-custom-kubernetes-workshop
# Create a build directive with Red Hat SSO official image stream.
oc new-build --name custom-sso73-openshift --binary --strategy source --image-stream redhat-sso73-openshift:1.0

# Start the custom build
oc start-build custom-sso73-openshift --from-dir . --follow

oc new-project evals07-spring
cd ~/secured-example
oc create -f service.sso.yaml

export MAVEN_OPTS="-Xmx1024M -Xss128M -XX:MetaspaceSize=512M -XX:MaxMetaspaceSize=1024M -XX:+CMSClassUnloadingEnabled"

mvn clean fabric8:deploy -Popenshift -DskipTests \
          -DSSO_AUTH_SERVER_URL=$(oc get route secure-sso -o jsonpath='{"https://"}{.spec.host}{"/auth\n"}')

curl -sk -X POST https://secure-sso-evals07-spring.apps.sso-3e67.open.redhat.com/auth/realms/master/protocol/openid-connect/token \
  -d grant_type=password \
  -d username=alice\
  -d password=password \
  -d client_id=demoapp \
  -d client_secret=1daa57a2-b60e-468b-a3ac-25bd2dc2eadc | jq -r .access_token

curl -v -H "Authorization: Bearer $TOKEN" http://rest-secured-evals07-spring.apps.sso-3e67.open.redhat.com/api/greeting

oc new-project evals07-spring-integration
oc create -f service.sso.yaml
export MAVEN_OPTS="-Xmx1024M -Xss128M -XX:MetaspaceSize=512M -XX:MaxMetaspaceSize=1024M -XX:+CMSClassUnloadingEnabled"

mvn clean verify -Popenshift,openshift-it -DSSO_AUTH_SERVER_URL=$(oc get route secure-sso -o jsonpath='{"https://"}{.spec.host}{"/auth\n"}')

oc new-project evals07-quarkus
# compiles an uber jar for our quarkus app.
export MAVEN_OPTS="-Xmx1024M -Xss128M -XX:MetaspaceSize=512M -XX:MaxMetaspaceSize=1024M -XX:+CMSClassUnloadingEnabled"
mvn clean package -DuberJar

# create a new build called kstart, we will use the OpenJDK images provided by Red Hat
oc new-build registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:1.5 --binary --name=kstart -l app=kstart

# Lets start our build, this will deploy our jar file using the OpenJDK image to Openshift
oc start-build kstart --from-file target/*-runner.jar --follow

# create a new app from our newly created image
oc new-app kstart

# expose our service
oc expose svc/kstart

oc get route kstart
```