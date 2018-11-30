FROM ubuntu:wzh

RUN apt-get update -y && apt-get upgrade -y && apt-get -y install wget curl sudo multitail man

COPY driver/mysql-connector-java_8.0.12-1ubuntu16.04_all.deb /root/

RUN apt-get -y install /root/mysql-connector-java_8.0.12-1ubuntu16.04_all.deb && rm -f /root/mysql-connector-java_8.0.12-1ubuntu16.04_all.deb && wget https://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh/archive.key -O archive.key && apt-key add archive.key && rm -f archive.key && wget 'https://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh/cloudera.list' -O /etc/apt/sources.list.d/cloudera.list && wget 'https://archive.cloudera.com/gplextras5/ubuntu/precise/amd64/gplextras/cloudera.list' -O /etc/apt/sources.list.d/gplextras.list && apt-get update -y &&  apt-get install hadoop-yarn-resourcemanager hadoop-hdfs-namenode hadoop-hdfs-secondarynamenode hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce hadoop-mapreduce-historyserver hadoop-yarn-proxyserver hadoop-client hadoop-lzo hadoop-httpfs hive hive-metastore hive-server2 hive-jdbc impala impala-server impala-state-store impala-catalog impala-shell impala-lzo impala-udf-dev -y && apt-get -y clean

RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys