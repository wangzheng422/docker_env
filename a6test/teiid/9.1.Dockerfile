FROM teiid:wzh

USER root

RUN yum -y update && yum -y install epel-release && yum -y update && yum -y install supervisor

COPY conf/supervisord.ini /etc/supervisor/conf.d/app.ini

USER jboss

RUN $JBOSS_HOME/bin/add-user.sh -u root -p root -e

COPY vdb.xml $JBOSS_HOME/

USER root

# Run Teiid server and bind to all interface
CMD ["/bin/sh","-c","tail -f /etc/supervisor/conf.d/app.ini"]
