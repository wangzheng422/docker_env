FROM flume:build

# ENV JAVA_HOME /opt/java
ENV PATH /opt/flume/bin:$PATH

WORKDIR /app
RUN mvn clean install -DskipTests