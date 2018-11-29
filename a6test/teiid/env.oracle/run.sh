#!/usr/bin/env bash

set -e
set -x

docker-compose up -d -V

# sleep 10

# docker-compose exec teiid-master /opt/jboss/wildfly/bin/add-user.sh -u root -p root -e

# docker-compose exec teiid-master /opt/jboss/wildfly/bin/add-user.sh -a -u app -p app -e

# docker exec -it filebeat
# docker-compose exec filebeat bash
# ./filebeat setup --dashboards