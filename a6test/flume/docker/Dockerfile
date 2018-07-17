FROM centos:wzh

RUN yum -y install java-1.8.0-openjdk wget && mkdir /opt/flume && wget -qO- http://archive.apache.org/dist/flume/1.8.0/apache-flume-1.8.0-bin.tar.gz \
          | tar zxvf - -C /opt/flume --strip 1

# ENV JAVA_HOME /opt/java
ENV PATH /opt/flume/bin:$PATH

COPY start-flume.sh /opt/flume/bin/start-flume
COPY flume.conf /opt/flume-config/
COPY morphline.conf /opt/flume-config/
COPY log4j.properties /opt/flume-config/

RUN chmod +x /opt/flume/bin/start-flume

ENTRYPOINT [ "/opt/flume/bin/start-flume" ]