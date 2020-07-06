FROM docker.io/wangzheng422/cloudnative-workspaces-quarkus:2020-07-06

RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m1-labs && cd cloud-native-workshop-v2m1-labs && git checkout ocp-4.4 && for proj in catalog inventory monolith  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m1-labs 
