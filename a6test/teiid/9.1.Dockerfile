FROM teiid:wzh

USER root

RUN yum -y update && yum -y install epel-release && yum -y update && yum -y install supervisor

USER jboss

RUN $JBOSS_HOME/bin/add-user.sh -u root -p root -e

COPY vdb.xml $JBOSS_HOME/

USER root

# Run Teiid server and bind to all interface
CMD ["/usr/bin/supervisord"]
