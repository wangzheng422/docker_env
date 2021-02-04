FROM hadoop:base


COPY conf/hive/mysql-connector-java-8.0.11.jar /opt/hive/lib/
COPY conf/hive/elasticsearch-hadoop-hive-6.2.4.jar /opt/hive/lib/
COPY conf/hive/hive-env.sh /opt/hive/conf/hive-env.sh
# COPY conf/hive/hive-site.xml /opt/hive/conf/hive-node-hive-site.xml
COPY conf/hive/hive-site.xml /opt/hive/conf/
COPY conf/hive/hive-log4j.properties /opt/hive/conf/
COPY conf/hive/hive-exec-log4j2.properties /opt/hive/conf/
COPY conf/hive/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Pseudo-Distributed Operation
# COPY conf/datanode/core-site.xml etc/hadoop/data-node-core-site.xml
# COPY conf/datanode/hdfs-site.xml etc/hadoop/data-node-hdfs-site.xml
# COPY conf/datanode/yarn-site.xml etc/hadoop/data-node-yarn-site.xml
# COPY conf/datanode/mapred-site.xml etc/hadoop/data-node-mapred-site.xml
# COPY conf/namenode/core-site.xml etc/hadoop/name-node-core-site.xml
# COPY conf/namenode/hdfs-site.xml etc/hadoop/name-node-hdfs-site.xml
# COPY conf/namenode/yarn-site.xml etc/hadoop/name-node-yarn-site.xml
# COPY conf/namenode/mapred-site.xml etc/hadoop/name-node-mapred-site.xml

COPY conf/namenode/core-site.xml etc/hadoop/
COPY conf/namenode/hdfs-site.xml etc/hadoop/
COPY conf/namenode/yarn-site.xml etc/hadoop/
COPY conf/namenode/mapred-site.xml etc/hadoop/
COPY conf/namenode/hadoop-env.sh etc/hadoop/

COPY schema/* /opt/schema/


COPY entrypoint.sh /
COPY run-wordcount.sh /
COPY conf/ssh_config /root/.ssh/config
RUN chmod a+x /*.sh
ENTRYPOINT "/entrypoint.sh"

