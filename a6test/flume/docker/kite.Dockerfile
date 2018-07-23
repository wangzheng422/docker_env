FROM centos:wzh

RUN yum -y install java-1.8.0-openjdk maven wget git && mkdir /app 

RUN cd /app && git clone https://github.com/kite-sdk/kite

# WORKDIR /app
RUN cd /app/kite/ && mvn clean install -DskipTests