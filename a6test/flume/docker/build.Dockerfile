FROM centos:wzh

RUN yum -y install java-1.8.0-openjdk maven wget && mkdir /app && wget -qO- http://ftp.cuhk.edu.hk/pub/packages/apache.org/flume/1.8.0/apache-flume-1.8.0-src.tar.gz \
          | tar zxvf - -C /app --strip 1

WORKDIR /app
RUN mvn clean install -DskipTests