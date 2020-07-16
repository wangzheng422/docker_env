FROM quay.io/openshiftlabs/cloudnative-workspaces-quarkus:2.1

RUN rm -rf /root/.m2
RUN rm -rf /home/jboss/.m2

RUN mkdir -p /root/.m2
COPY settings.xml /root/.m2/
COPY .npmrc /root/

USER jboss

RUN mkdir -p /home/jboss/.m2/
COPY settings.xml /home/jboss/.m2/
COPY .npmrc /home/jboss/

COPY order-service.tgz /tmp/

RUN cd /tmp && tar zxf order-service.tgz && cd order-service && mvn -fn  clean package -DskipTests -f .

# https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2-labs-solutions
# RUN cd /tmp && git clone https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2-labs-solutions && cd cloud-native-workshop-v2-labs-solutions && git checkout master && for proj in m1/catalog m1/inventory m1/monolith m2/catalog m2/inventory m2/monitoring m2/monolith m3/catalog m3/inventory m4/cart-service m4/catalog-service  m4/inventory-service  m4/order-service  m4/payment-service ; do mvn -fn  dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests -f ./$proj ; mvn -fn  clean package -f ./$proj  ; mvn -fn clean install spring-boot:repackage -DskipTests -f ./$proj ; mvn -fn clean spring-boot:start -f ./$proj ; mvn -fn clean spring-boot:stop -f ./$proj ; mvn -fn quarkus:add-extension -Dextensions="quarkus-agroal,quarkus-arc,quarkus-hibernate-orm,quarkus-hibernate-orm-panache,quarkus-jdbc-h2,quarkus-jdbc-postgresql,quarkus-kubernetes,quarkus-scheduler,quarkus-smallrye-fault-tolerance,quarkus-smallrye-health,quarkus-smallrye-opentracing,quarkus-smallrye-reactive-streams-operators,quarkus-smallrye-reactive-messaging,quarkus-smallrye-reactive-messaging-kafka,quarkus-swagger-ui,quarkus-vertx,quarkus-kafka-client, quarkus-smallrye-metrics,quarkus-smallrye-openapi" -f ./$proj ; mvn -fn  clean package -DskipTests -f ./$proj  ;  done 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m4-labs && cd cloud-native-workshop-v2m4-labs && git checkout ocp-4.4  && for proj in cart-service catalog-service  inventory-service  order-service  payment-service ; do  mvn -fn  clean package -DskipTests -f ./$proj ;  done 

# RUN cd /tmp && rm -rf /tmp/cloud-native*


# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2-labs-solutions && cd cloud-native-workshop-v2-labs-solutions && git checkout master && cd m4  && for proj in order-service  ; do mvn -fn quarkus:add-extension -Dextensions="resteasy-jsonb,mongodb-client" -f ./$proj  ; mvn -fn  dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests -f ./$proj ;  mvn -fn  clean package -DskipTests -f ./$proj ;  done 

# RUN cd /tmp && rm -rf /tmp/cloud-native*

# RUN cd /tmp && git clone https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m4-labs && cd cloud-native-workshop-v2m4-labs && git checkout ocp-4.4  && for proj in order-service  ; do mvn -fn quarkus:add-extension -Dextensions="resteasy-jsonb,mongodb-client" -f ./$proj  ; mvn -fn  clean package -DskipTests -f ./$proj ;  done 


# RUN cd /tmp && rm -rf /tmp/cloud-native*


# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m1-labs && cd cloud-native-workshop-v2m1-labs && git checkout ocp-4.4 && for proj in catalog inventory monolith  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests; mvn -fn -f ./$proj  clean package  ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m1-labs 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m2-labs && cd cloud-native-workshop-v2m2-labs && git checkout ocp-4.4 && for proj in catalog inventory monolith  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ;  mvn -fn -f ./$proj  clean package  ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m2-labs 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m3-labs && cd cloud-native-workshop-v2m3-labs && git checkout ocp-4.4 && for proj in catalog inventory  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ;  mvn -fn -f ./$proj  clean package  ; done && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m3-labs 

# RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m4-labs && cd cloud-native-workshop-v2m4-labs && git checkout ocp-4.4 && for proj in *-service  ; do mvn -fn -f ./$proj dependency:resolve-plugins dependency:resolve dependency:go-offline clean compile -DskipTests ;  mvn -fn -f ./$proj  clean package  ; done && cd /tmp/cloud-native-workshop-v2m4-labs/coolstore-ui && npm install --save-dev nodeshift && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m4-labs 

RUN cd /tmp && git clone https://github.com/wangzheng422/cloud-native-workshop-v2m4-labs && cd cloud-native-workshop-v2m4-labs && git checkout ocp-4.4 && cd /tmp/cloud-native-workshop-v2m4-labs/coolstore-ui && npm install --save-dev nodeshift && cd /tmp && rm -rf /tmp/cloud-native-workshop-v2m4-labs 

USER root
RUN chown -R jboss /home/jboss/.m2
RUN chown -R jboss /home/jboss/.config
RUN chmod -R a+rwx /home/jboss/.m2
RUN chmod -R a+rwx /home/jboss/.config
RUN chmod -R a+rwx /home/jboss/.siege

RUN rm -rf /tmp/*
RUN ls /tmp

