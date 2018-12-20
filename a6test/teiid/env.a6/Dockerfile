FROM teiid:wzh


COPY vdb1-vdb.xml $JBOSS_HOME/standalone/deployments/
COPY vdb2-vdb.xml $JBOSS_HOME/standalone/deployments/

RUN rm -f $JBOSS_HOME/standalone/deployments/vdb1-vdb.xml
RUN rm -f $JBOSS_HOME/standalone/deployments/vdb2-vdb.xml

COPY tmp/* $JBOSS_HOME/standalone/deployments/
