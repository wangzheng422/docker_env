FROM teiid:wzh

RUN rm -f $JBOSS_HOME/standalone/deployments/*

COPY tmp/*.vdb $JBOSS_HOME/standalone/deployments/

COPY tmp/standalone-teiid.xml $JBOSS_HOME/standalone/configuration/

RUN touch $JBOSS_HOME/standalone/deployments/JD_UDB.vdb.dodeploy

RUN /opt/jboss/wildfly/bin/add-user.sh -u root -p root -e
RUN /opt/jboss/wildfly/bin/add-user.sh -a -u app -p app -e -g odata
