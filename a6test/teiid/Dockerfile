FROM jboss/wildfly:11.0.0.Final

ENV JBOSS_HOME /opt/jboss/wildfly

# Set the TEIID_VERSION env variable
ENV TEIID_VERSION 10.2.1

# Download and unzip Teiid server
RUN cd $JBOSS_HOME \
    && curl -O https://oss.sonatype.org/service/local/repositories/releases/content/org/teiid/teiid/$TEIID_VERSION/teiid-$TEIID_VERSION-wildfly-dist.zip \
    && bsdtar -xf teiid-$TEIID_VERSION-wildfly-dist.zip \
    && chmod +x $JBOSS_HOME/bin/*.sh \
    && rm teiid-$TEIID_VERSION-wildfly-dist.zip

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
COPY entrypoint.sh /opt/jboss/

USER root
RUN chmod a+x /opt/jboss/entrypoint.sh

USER jboss

# ENTRYPOINT "/opt/jboss/entrypoint.sh"
CMD ["/bin/sh", "-c", "$JBOSS_HOME/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0"]