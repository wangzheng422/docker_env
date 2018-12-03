FROM flume:build as builder

# COPY flume-ng-morphline-solr-sink-pom.xml /app/flume-ng-sinks/flume-ng-morphline-solr-sink/pom.xml 

# COPY flume-hdfs-sink-pom.xml /app/flume-ng-sinks/flume-ng-sinks/flume-hdfs-sink/pom.xml

# COPY pom.xml /app/pom.xml

COPY src/AvroEventSerializer.java /app/flume-ng-sinks/flume-hdfs-sink/src/main/java/org/apache/flume/sink/hdfs/

# COPY src/checkstyle-suppressions.xml /app/flume-checkstyle/src/main/resources/flume/checkstyle-suppressions.xml

WORKDIR /app
RUN mvn clean install -DskipTests


FROM kite:build as kite

COPY --from=kite:build /app/kite/kite-morphlines/kite-morphlines-all/target/*.jar  /opt/flume/plugins.d/morphline/lib/
COPY --from=kite:build /app/kite/kite-morphlines/kite-morphlines-all/target/lib/*.jar  /opt/flume/plugins.d/morphline/libext/

# FROM hadoop:wzh as hadooper

FROM centos:wzh

# ENV JAVA_HOME /opt/java
ENV PATH /opt/flume/bin:$PATH

COPY --from=builder /app/flume-ng-dist/target/apache-flume-1.8.0-bin.tar.gz /opt/

# COPY --from=builder /app/flume-ng-dist/target/apache-flume-1.7.0-bin.tar.gz /opt/


# COPY --from=hadooper /opt/hadoop /opt/hadoop
# ENV HADOOP_HOME /opt/hadoop
# ENV PATH /opt/hadoop/bin:/opt/hadoop/sbin:/opt/hive/bin:$PATH
# ENV WZH_JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.171-8.b10.el7_5.x86_64/
# RUN sed --in-place='.ori' -e "s/\${WZH_JAVA_HOME}/\/usr\/lib\/jvm\/java-8-openjdk-amd64/" /opt/hadoop/etc/hadoop/hadoop-env.sh

RUN yum -y install java-1.8.0-openjdk wget && mkdir -p /opt/flume && mkdir -p /opt/schema &&  tar zxvf /opt/apache-flume-1.8.0-bin.tar.gz -C /opt/flume --strip 1 && rm -f /opt/apache-flume-1.8.0-bin.tar.gz && mkdir -p /opt/flume/plugins.d/hdfs-sink/conf && mkdir -p /opt/flume/plugins.d/hdfs-sink/lib && mkdir -p /opt/flume/plugins.d/hdfs-sink/libext && mkdir -p /opt/flume/plugins.d/hdfs-sink/native && mkdir -p /opt/flume/plugins.d/morphline/conf && mkdir -p /opt/flume/plugins.d/morphline/lib && mkdir -p /opt/flume/plugins.d/morphline/libext && mkdir -p /opt/flume/plugins.d/morphline/native

# RUN yum -y install java-1.8.0-openjdk wget && mkdir -p /opt/flume && mkdir -p /opt/schema &&  tar zxvf /opt/apache-flume-1.7.0-bin.tar.gz -C /opt/flume --strip 1 && rm -f /opt/apache-flume-1.7.0-bin.tar.gz && mkdir -p /opt/flume/plugins.d/hdfs-sink/conf && mkdir -p /opt/flume/plugins.d/hdfs-sink/lib && mkdir -p /opt/flume/plugins.d/hdfs-sink/libext && mkdir -p /opt/flume/plugins.d/hdfs-sink/native && mkdir -p /opt/flume/plugins.d/morphline/conf && mkdir -p /opt/flume/plugins.d/morphline/lib && mkdir -p /opt/flume/plugins.d/morphline/libext && mkdir -p /opt/flume/plugins.d/morphline/native

COPY --from=hadooper /opt/hadoop/share/hadoop/common/*.jar /opt/flume/plugins.d/hdfs-sink/lib/
COPY --from=hadooper /opt/hadoop/share/hadoop/common/lib/*.jar /opt/flume/plugins.d/hdfs-sink/libext/
COPY --from=hadooper /opt/hadoop/share/hadoop/hdfs/*.jar /opt/flume/plugins.d/hdfs-sink/lib/
COPY --from=hadooper /opt/hadoop/share/hadoop/hdfs/lib/*.jar /opt/flume/plugins.d/hdfs-sink/libext/
COPY --from=hadooper /opt/hadoop/lib/native/* /opt/flume/plugins.d/hdfs-sink/native/
# COPY woodstox-core-5.1.0.jar /opt/flume/lib/

COPY start-flume.sh /opt/flume/bin/start-flume
COPY flume.conf /opt/flume-config/
COPY morphline.conf /opt/flume-config/
COPY log4j.properties /opt/flume-config/
COPY flume-env.sh /opt/flume-config/
COPY schema/* /opt/schema/

COPY core-site.xml /opt/flume-config/
COPY hdfs-site.xml /opt/flume-config/

# RUN cp -f /opt/flume-config/* /opt/hadoop/etc/hadoop/

RUN chmod +x /opt/flume/bin/start-flume 

ENTRYPOINT [ "/opt/flume/bin/start-flume" ]

