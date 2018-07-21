FROM flume:build as builder

COPY flume-ng-morphline-solr-sink-pom.xml /app/flume-ng-sinks/flume-ng-morphline-solr-sink/pom.xml 

# COPY flume-hdfs-sink-pom.xml /app/flume-ng-sinks/flume-ng-sinks/flume-hdfs-sink/pom.xml

WORKDIR /app
RUN mvn clean install -DskipTests