FROM cdh:base

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

COPY conf/namenode/core-site.xml /etc/hadoop/conf/
COPY conf/namenode/hdfs-site.xml /etc/hadoop/conf/
COPY conf/namenode/yarn-site.xml /etc/hadoop/conf/
COPY conf/namenode/mapred-site.xml /etc/hadoop/conf/
# COPY conf/namenode/hadoop-env.sh /etc/hadoop/

COPY conf/hive/ /etc/hive/conf/
COPY conf/default/ /etc/default/

COPY conf/flume/ /etc/flume-ng/conf/

EXPOSE 9000 8088 50070 9999

COPY entrypoint.sh /
COPY conf/ssh_config /root/.ssh/config
RUN chmod a+x /*.sh
ENTRYPOINT "/entrypoint.sh"