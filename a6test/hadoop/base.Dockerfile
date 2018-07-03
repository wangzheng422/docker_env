FROM ubuntu:16.04


RUN apt-get update && apt-get install -y openjdk-8-jdk curl ssh iproute2 net-tools dnsutils vim supervisor

RUN mkdir -p /data/hdfs/
RUN mkdir -p /opt
WORKDIR /opt

# Install Hadoop
RUN curl -L http://ftp.cuhk.edu.hk/pub/packages/apache.org/hadoop/common/hadoop-2.9.1/hadoop-2.9.1.tar.gz -s -o - | tar -xzf - && mv hadoop-2.* hadoop

RUN curl -L http://ftp.cuhk.edu.hk/pub/packages/apache.org/hive/hive-2.3.3/apache-hive-2.3.3-bin.tar.gz -s -o - | tar -xzf - && mv apache-hive* hive
# RUN mv hadoop-2.* hadoop
ENV HADOOP_HOME /opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV HIVE_CONF_DIR=/opt/hive/conf



# Setup
WORKDIR /opt/hadoop
ENV PATH /opt/hadoop/bin:/opt/hadoop/sbin:/opt/hive/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN sed --in-place='.ori' -e "s/\${JAVA_HOME}/\/usr\/lib\/jvm\/java-8-openjdk-amd64/" etc/hadoop/hadoop-env.sh



RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

EXPOSE 9000 8088 50070 9999

# SSH login fix. Otherwise user is kicked off after login
# RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# ENV NOTVISIBLE "in users profile"
# RUN echo "export VISIBLE=now" >> /etc/profile

VOLUME /data/



