FROM centos:wzh

RUN yum -y install java-1.8.0-openjdk wget && mkdir /opt/flume && wget -qO- http://archive.apache.org/dist/flume/1.8.0/apache-flume-1.8.0-bin.tar.gz \
          | tar zxvf - -C /opt/flume --strip 1

# ENV JAVA_HOME /opt/java
ENV PATH /opt/flume/bin:$PATH

ADD start-flume.sh /opt/flume/bin/start-flume
ADD flume.conf /opt/flume-config/

ENTRYPOINT [ "start-flume" ]