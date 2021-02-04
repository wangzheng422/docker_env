FROM debezium/connect:0.9

ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc
ENV INSTANT_CLIENT_DIR=/instant_client/

USER root
RUN yum -y install libaio && yum clean all

USER kafka
# Deploy Oracle client and drivers

COPY tmp/instantclient_12_2/* $INSTANT_CLIENT_DIR
COPY tmp/instantclient_12_2/xstreams.jar /kafka/libs
COPY tmp/instantclient_12_2/ojdbc8.jar /kafka/libs

# COPY driver/ojdbc/* /kafka/libs/
