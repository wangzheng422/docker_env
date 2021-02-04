#!/usr/bin/env bash

set -e
set -x

mkdir -p /home/vagrant/oradata/recovery_area
sudo chgrp 54321 /home/vagrant/oradata
sudo chown 54321 /home/vagrant/oradata
sudo chgrp 54321 /home/vagrant/oradata/recovery_area
sudo chown 54321 /home/vagrant/oradata/recovery_area

docker-compose up -d -V

# docker exec -it filebeat
# docker-compose exec filebeat bash
# ./filebeat setup --dashboards