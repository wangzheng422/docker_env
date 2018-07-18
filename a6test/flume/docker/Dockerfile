FROM flume:build as builder

COPY flume-ng-morphline-solr-sink-pom.xml /app/flume-ng-sinks/flume-ng-morphline-solr-sink/pom.xml 

COPY flume-hdfs-sink-pom.xml /app/flume-ng-sinks/flume-ng-sinks/flume-hdfs-sink/pom.xml

WORKDIR /app
RUN mvn clean install -DskipTests

FROM hadoop:wzh as hadooper

FROM centos:wzh

# ENV JAVA_HOME /opt/java
ENV PATH /opt/flume/bin:$PATH

COPY --from=builder /app/flume-ng-dist/target/apache-flume-1.8.0-bin.tar.gz /opt/

RUN yum -y install java-1.8.0-openjdk wget && mkdir /opt/flume &&  tar zxvf /opt/apache-flume-1.8.0-bin.tar.gz -C /opt/flume --strip 1 && rm -f /opt/apache-flume-1.8.0-bin.tar.gz

COPY --from=hadooper /opt/hadoop/share/hadoop/common/*.jar /opt/flume/lib/
COPY --from=hadooper /opt/hadoop/share/hadoop/common/lib/*.jar /opt/flume/lib/

COPY start-flume.sh /opt/flume/bin/start-flume
COPY flume.conf /opt/flume-config/
COPY morphline.conf /opt/flume-config/
COPY log4j.properties /opt/flume-config/
COPY flume-env.sh /opt/flume-config/

COPY core-site.xml /opt/flume-config/
COPY hdfs-site.xml /opt/flume-config/

RUN chmod +x /opt/flume/bin/start-flume && mkdir -p /opt/schema

ENTRYPOINT [ "/opt/flume/bin/start-flume" ]

