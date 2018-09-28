FROM cdh:base

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64



RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

EXPOSE 9000 8088 50070 9999

COPY entrypoint.sh /
COPY conf/ssh_config /root/.ssh/config
RUN chmod a+x /*.sh
ENTRYPOINT "/entrypoint.sh"