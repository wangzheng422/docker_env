FROM flume:build

# ENV JAVA_HOME /opt/java
ENV PATH /opt/flume/bin:$PATH

COPY flume-ng-morphline-solr-sink-pom.xml /app/flume-ng-sinks/flume-ng-morphline-solr-sink/pom.xml 

WORKDIR /app
RUN mvn clean install -DskipTests