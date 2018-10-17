#!/usr/bin/env bash


PREFIX="-------- "
echo $PREFIX"Bootstraping teiid..."



if [ "$SERVER_ROLE" = "master" ]; then
    echo $PREFIX"Will start as master"

    cp -f /opt/jboss/wildfly/domain/configuration/host-master.xml /opt/jboss/wildfly/domain/configuration/host.xml

    /opt/jboss/wildfly/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0

else
  echo $PREFIX"Will start as slave"

  cp -f /opt/jboss/wildfly/domain/configuration/host-slave.xml /opt/jboss/wildfly/domain/configuration/host.xml

  sleep 60

  /opt/jboss/wildfly/bin/domain.sh --master-address=${MASTER_ADDR} -b 0.0.0.0 -bmanagement 0.0.0.0

fi

wait || :
