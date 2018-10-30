FROM teiid:wzh

RUN $JBOSS_HOME/bin/add-user.sh -u root -p root -e

COPY vdb.xml $JBOSS_HOME/standalone/deployments/

# Run Teiid server and bind to all interface
CMD ["/bin/sh", "-c", "$JBOSS_HOME/bin/standalone.sh -c standalone-teiid.xml -b 0.0.0.0 -bmanagement 0.0.0.0"]
