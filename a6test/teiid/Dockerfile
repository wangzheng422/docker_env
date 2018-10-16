FROM jboss/teiid

COPY entrypoint.sh /opt/jboss/
RUN chmod a+x /opt/jboss/entrypoint.sh
ENTRYPOINT "/entrypoint.sh"