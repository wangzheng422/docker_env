FROM docker.io/wangzheng422/cloudnative-workspaces-quarkus:2020-07-07

USER jboss

# https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2-labs-solutions
# RUN cd /tmp && git clone https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2-labs-solutions && cd cloud-native-workshop-v2-labs-solutions && git checkout master && for proj in m1/catalog m1/inventory m1/monolith m2/catalog m2/inventory m2/monitoring m2/monolith m3/catalog m3/inventory m4/*-service ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2-labs-solutions


RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m1-labs && cd cloud-native-workshop-v2m1-labs && git checkout ocp-4.4 && for proj in catalog inventory monolith  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests; mvn -fn -f ./$proj  clean package  ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m1-labs 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m2-labs && cd cloud-native-workshop-v2m2-labs && git checkout ocp-4.4 && for proj in catalog inventory monolith  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m2-labs 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m3-labs && cd cloud-native-workshop-v2m3-labs && git checkout ocp-4.4 && for proj in catalog inventory  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m3-labs 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m4-labs && cd cloud-native-workshop-v2m4-labs && git checkout ocp-4.4 && for proj in *-service  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ; done && cd /tmp/cloud-native-workshop-v2m4-labs/coolstore-ui && npm install --save-dev nodeshift && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m4-labs 

