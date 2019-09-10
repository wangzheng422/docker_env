#!/bin/bash

#service mysql start
/usr/sbin/mysqld --daemonize --pid-file=/run/mysqld/mysqld.pid
cd /opt/gpu_models
bash ./start.sh &
cd /opt/tomcat/bin
./startup.sh
cd ../logs
tail -f catalina.out