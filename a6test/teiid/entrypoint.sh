#!/usr/bin/env bash


PREFIX="-------- "
echo $PREFIX"Bootstraping teiid..."



if [ "$SERVER_ROLE" = "master" ]; then
    echo $PREFIX"Will start as master"

    /opt/jboss/wildfly/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0

else
  echo $PREFIX"Will start as slave"

  /opt/jboss/wildfly/bin/domain.sh --master-address=${MASTER_ADDR} -b 0.0.0.0 -bmanagement 0.0.0.0

fi

wait || :
