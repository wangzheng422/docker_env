FROM jboss/teiid

COPY entrypoint.sh /opt/jboss/
USER root
RUN chmod a+x /opt/jboss/entrypoint.sh
USER jboss
ENTRYPOINT "/opt/jboss/entrypoint.sh"