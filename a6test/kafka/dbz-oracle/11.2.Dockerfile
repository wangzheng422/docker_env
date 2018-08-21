FROM debezium/connect:0.9

ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc
ENV INSTANT_CLIENT_DIR=/instant_client/

USER root
RUN yum -y install libaio && yum clean all

USER kafka
# Deploy Oracle client and drivers

COPY tmp/instantclient_11_2/* $INSTANT_CLIENT_DIR
COPY tmp/instantclient_11_2/xstreams.jar /kafka/libs
COPY tmp/instantclient_11_2/ojdbc*.jar /kafka/libs/

# COPY driver/ojdbc/* /kafka/libs/
RUN rm -f /kafka/connect/debezium-connector-oracle/debezium-*.jar
COPY tmp/*.jar $KAFKA_CONNECT_PLUGINS_DIR/debezium-connector-oracle/

COPY log4j.properties /kafka/config/
