FROM jboss/base-jdk:8

USER root

RUN yum -y update && yum -y install epel-release && yum -y update && yum -y install supervisor

COPY conf/supervisord.ini /etc/supervisord.d/app.ini

ENV JBOSS_HOME /opt/jboss/wildfly

# Set the TEIID_VERSION env variable
ENV TEIID_VERSION 11.2.0

USER root

# Download and unzip Teiid server
RUN cd $HOME \
    && curl -O https://oss.sonatype.org/service/local/repositories/releases/content/org/teiid/teiid/$TEIID_VERSION/teiid-$TEIID_VERSION-wildfly-server.zip \
    && bsdtar -xf teiid-$TEIID_VERSION-wildfly-server.zip \
    && mv $HOME/teiid-$TEIID_VERSION $JBOSS_HOME \
    && chmod +x $JBOSS_HOME/bin/*.sh \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME} \
    && rm teiid-$TEIID_VERSION-wildfly-server.zip

# RUN cd $JBOSS_HOME \
#     && curl -O https://oss.sonatype.org/service/local/repositories/releases/content/org/teiid/teiid/$TEIID_VERSION/teiid-$TEIID_VERSION-wildfly-server.zip \
#     && bsdtar -xf teiid-$TEIID_VERSION-wildfly-server.zip \
#     && chmod +x $JBOSS_HOME/bin/*.sh \
#     && rm teiid-$TEIID_VERSION-wildfly-server.zip

# RUN cd $JBOSS_HOME \
#     && curl -O https://repository.jboss.org/nexus/service/local/repositories/releases/content/org/jboss/teiid/hal/dist/3.0.1/dist-3.0.1-overlay.zip \
#     && bsdtar -xf dist-3.0.1-overlay.zip \
#     && chmod +x $JBOSS_HOME/bin/*.sh \
#     && rm dist-3.0.1-overlay.zip

# VOLUME ["$JBOSS_HOME/standalone", "$JBOSS_HOME/domain"]

USER jboss

ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Expose Teiid server  ports 
EXPOSE 8080 9990 31000 35432 

# COPY conf/ /opt/jboss/wildfly/domain/configuration/
# COPY entrypoint.sh /opt/jboss/

# USER root
# RUN chmod a+x /opt/jboss/entrypoint.sh

USER jboss

# ENTRYPOINT "/opt/jboss/entrypoint.sh"
# CMD ["/bin/sh", "-c", "$JBOSS_HOME/bin/standalone.sh -c standalone-teiid.xml -b 0.0.0.0 -bmanagement 0.0.0.0"]

COPY postgresql/modules/org/postgresql/main/ $JBOSS_HOME/modules/org/postgresql/main/

COPY oracle/modules/com/oracle/main/ $JBOSS_HOME/modules/com/oracle/main/

COPY vdb1-vdb.xml $JBOSS_HOME/standalone/deployments/
COPY vdb2-vdb.xml $JBOSS_HOME/standalone/deployments/

COPY conf/standalone-teiid.xml $JBOSS_HOME/standalone/configuration/

RUN /opt/jboss/wildfly/bin/add-user.sh -u root -p root -e
RUN /opt/jboss/wildfly/bin/add-user.sh -a -u app -p app -e

# USER root

# Run Teiid server and bind to all interface
# CMD ["/usr/bin/supervisord","-n"]
CMD ["/bin/sh", "-c", "$JBOSS_HOME/bin/standalone.sh -c standalone-teiid.xml -b 0.0.0.0 -bmanagement 0.0.0.0"]