FROM jboss/base-jdk:8

ENV JBOSS_HOME /opt/jboss/wildfly

# Set the TEIID_VERSION env variable
ENV TEIID_VERSION 9.0.0.Final

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
    

# VOLUME ["$JBOSS_HOME/standalone", "$JBOSS_HOME/domain"]

USER jboss

ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Expose Teiid server  ports 
EXPOSE 8080 9990 31000 35432 

# Run Teiid server and bind to all interface
CMD ["/bin/sh", "-c", "$JBOSS_HOME/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0"]
