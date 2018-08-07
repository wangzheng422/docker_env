FROM ubuntu:wzh

WORKDIR /opt

RUN wget http://mirror-hk.koddos.net/apache/tinkerpop/3.3.3/apache-tinkerpop-gremlin-console-3.3.3-bin.zip && wget http://ftp.cuhk.edu.hk/pub/packages/apache.org/tinkerpop/3.3.3/apache-tinkerpop-gremlin-server-3.3.3-bin.zip && unzip -q '*.zip' && rm *.zip