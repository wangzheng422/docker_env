FROM debezium/connect:0.9

ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc
ENV INSTANT_CLIENT_DIR=/instant_client/

USER root
RUN yum -y install libaio tcpdump sudo && yum clean all

RUN usermod -aG wheel kafka && \
    echo "kafka:kafka" | chpasswd && \
    sed -i -e 's/^\(%wheel\s\+.\+\)/#\1/gi' /etc/sudoers && \
    echo -e '\n%wheel ALL=(ALL) ALL' >> /etc/sudoers && \
    echo -e '\nDefaults:root   !requiretty' >> /etc/sudoers && \
    echo -e '\nDefaults:%wheel !requiretty' >> /etc/sudoers

USER kafka
# Deploy Oracle client and drivers

COPY tmp/instantclient_12_2/* $INSTANT_CLIENT_DIR
COPY tmp/instantclient_12_2/xstreams.jar /kafka/libs
COPY tmp/instantclient_12_2/ojdbc8.jar /kafka/libs

# -------- testing ---------
RUN rm -rf /kafka/connect/* && mkdir -p /kafka/connect/debezium-connector-oracle/
RUN rm -f /kafka/connect/debezium-connector-oracle/debezium-*.jar
COPY tmp/*.jar $KAFKA_CONNECT_PLUGINS_DIR/debezium-connector-oracle/
# COPY tmp/*embe*.jar /kafka/libs/

# RUN cp -f /kafka/config.orig/* /kafka/config/
COPY log4j/* /kafka/config/

