#!/bin/bash
#start rtmp server
#author:john at 2019/9/19
docker rm `docker ps -a|grep Exited|awk '{print $1}'`
docker run -itd -p 9999:9999 --name rtmp-server  haipenge/centos-7-nginx-rtmp
docker exec -it rtmp-server /bin/bash
cd /usr/local/nginx
./nginx
netstat -ntl
exit