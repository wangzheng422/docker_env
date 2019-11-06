#!/bin/bash
### BEGIN INIT INFO 
# Provides: Nginx
# Required-Start: $all 
# Required-Stop: $all 
# Default-Start: 3 5 
# Default-Stop: 0 1 6 
# Short-Description: Start and stop nginx mode 
# Description: Start and stop nginx in external FASTCGI mode 
### END INIT INFO 
# chkconfig: 2345 90 10
# description: nginx server daemon

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
oss=home
local_ip=10.128.18.13
IP_EXPR="^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"
cd $dir/installs

if [ ! -d "/$oss/nasdata/" ] ;then
    mkdir -p /$oss/nasdata
fi

if [ ! -d "$dir/lib/" ] ;then
    tar -zxvf lib.tar.gz -C ../ > /dev/null
fi

if [ ! -d "$dir/ext/" ] ;then
    tar -zxvf ext.tar.gz -C ../ > /dev/null
fi

if [ ! -d "$dir/Feature_config/" ] ;then
    tar -zxvf Feature_config.tar.gz -C ../ > /dev/null
fi

if [ ! -d "$dir/Recog_config/" ] ;then
    tar -zxvf Recog_config.tar.gz -C ../ > /dev/null
fi

if [ ! -d "$dir/recogdata/" ] ;then
    tar -zxvf recogdata.tar.gz -C ../ > /dev/null
fi

if [ ! -d "$dir/snapdata/" ] ;then
    tar -zxvf snapdata.tar.gz -C ../ > /dev/null
fi

function checkip()
{  

if [ -n "$(echo $local_ip | grep -E $IP_EXPR)" ]; then
    echo "1"
  else
    echo "0"

fi

}
function install()
{
n=`checkip`
if [[ $n -eq 1 ]]; then
echo -e "\033[32m\033[32m >>>>>>>> 开始安装  \033[0m"
zookeeper_exist=`docker ps -a|grep zk1`
if [ -n "$zookeeper_exist" ] ;then
    echo -e "\033[31m >>>>>>>> zookeeper已存在  \033[0m"
else
echo -e "\033[32m\033[32m >>>>>>>> 安装zookeeper  \033[0m"    
    docker load -i zookeeper-1.4.2.tar && docker run -d --rm -p 2181:2181 --name zk1 -v /etc/localtime:/etc/localtime zookeeper
fi
zookeeper_exist=`docker ps -a|grep zk1`
while [ -z "$zookeeper_exist" ]
do
	echo "zookeeper starting"
	sleep 10
        zookeeper_exist=`docker ps -a|grep zk1`
done

sleep 10 
kafka_exist=`docker ps -a|grep kafka-1.4.2`
if [ -n "$kafka_exist" ] ;then
    echo -e "\033[31m >>>>>>>> kafka已存在  \033[0m"
else
echo -e "\033[32m\033[32m >>>>>>>> 安装kafka  \033[0m" 
    docker load -i kafka-1.4.2.tar && docker run -d --rm --name kafka-1.4.2 -v /etc/localtime:/etc/localtime -p 9092:9092 --link zk1 --env KAFKA_ZOOKEEPER_CONNECT=zk1:2181 --env KAFKA_ADVERTISED_HOST_NAME=172.17.0.3 kafka:1.4.2 
fi

sleep 10
redis_exist=`docker ps -a|grep redis-1.4.2`
if [ -n "$redis_exist" ] ;then
    echo -e "\033[31m >>>>>>>> redis已存在  \033[0m"
else
echo -e "\033[32m\033[32m >>>>>>>> 安装redis  \033[0m" 
    docker load -i redis-1.4.2.tar && docker run -d  --name redis-1.4.2 -v /etc/localtime:/etc/localtime -p 6379:6379 redis:1.4.2 --requirepass 'Anfang@123!'
fi

sleep 10
mysql_exist=`docker ps -a|grep mysql-1.4.2`
if [ -n "$mysql_exist" ] ;then
    echo -e "\033[31m >>>>>>>> mysql已存在  \033[0m"
else
echo -e "\033[32m\033[32m >>>>>>>> 安装mysql  \033[0m" 	
    docker load -i mysql-1.4.2.tar && docker run -d --name mysql-1.4.2 -v $dir/lib/mysql:/var/lib/mysql -v /etc/localtime:/etc/localtime -p 3306:3306 mysql:1.4.2
#sleep 10 
#    docker exec mysql-1.4.2 bash /zpc/start

fi

sleep 10
nginx_exist=`docker ps -a|grep nginx-1.4.2`
if [ -n "$nginx_exist" ] ;then
    echo -e "\033[31m >>>>>>>> nginx已存在  \033[0m"
else
echo -e "\033[32m\033[32m >>>>>>>> 安装nginx  \033[0m"  
    docker load -i nginx-1.4.2.tar && docker run -d  --name=nginx-1.4.2 -e key_ocean=$local_ip -e key_facebigdata=$local_ip -e key_ocean_manage=$local_ip -e ocean_entry_http=$local_ip -e key_ocean_socket_ip=$local_ip -e key_ocean_ip=$local_ip -e ocean_manage_ip=$local_ip -e key_nginx_ip=$local_ip -v /$oss/nasdata:/home/nasdata -v /etc/localtime:/etc/localtime -p 10000:10000 -p 10001:10001 -p 10005:10005 -p 10007:10007 -p 10006:10006 -p 10011:10011 nginx:1.4.2
fi

sleep 10 
ocean_exist=`docker ps -a|grep ocean-1.4.2`
if [ -n "$ocean_exist" ] ;then
    echo -e "\033[31m >>>>>>>> ocean已存在  \033[0m"
else
echo -e "\033[32m\033[32m >>>>>>>> 安装ocean  \033[0m"  
     docker load -i ocean-1.4.2.tar && docker run -d  --name=ocean-1.4.2 -e nginx_img_url=$local_ip -e key_ocean_ip=$local_ip -e mysql_ip=$local_ip -e kafka_address=$local_ip:9092 -e zookeeper_address=$local_ip:2181 -e engine_ip=$local_ip -e orc_ip=$local_ip -e orc_live_ip=$local_ip -e redis_ip=$local_ip -e ftp_ip=$local_ip -v /$oss/nasdata:/home/nasdata -v /etc/localtime:/etc/localtime -p 11006:11006 ocean:1.4.2
fi

sleep 10 
manager_exist=`docker ps -a|grep ocean-manager-1.4.2`
if [ -n "$manager_exist" ] ;then
    echo -e "\033[31m >>>>>>>> manager已存在  \033[0m"
else
    echo -e "\033[32m\033[32m >>>>>>>> 安装manager  \033[0m"  
     docker load -i ocean-manager-1.4.2.tar && docker run -d  --name ocean-manager-1.4.2 -e nginx_ip=$local_ip -e mysql_ip=$local_ip -e key_ocean_manage=127.0.0.1 -e kafka_address=$local_ip:9092 -e zookeeper_address=$local_ip:2181 -e FaceGo_ip=$local_ip -e key_FaceGo_ip=$local_ip -e redis_ip=$local_ip -p 11007:11007 -v /$oss/nasdata:/home/nasdata -v /etc/localtime:/etc/localtime ocean-manager:1.4.2
fi

sleep 10 
socket_exist=`docker ps -a|grep ocean-socket-1.4.2`
if [ -n "$socket_exist" ] ;then
    echo -e "\033[31m >>>>>>>> ocean-socket已存在  \033[0m"
else
    echo -e "\033[32m\033[32m >>>>>>>> 安装ocean-socket  \033[0m" 
     docker load -i ocean-socket-1.4.2.tar && docker run  -d --rm --name ocean-socket-1.4.2 -e ocean_socket_ip=127.0.0.1 -e nginx_ip=$local_ip -e kafka_address=$local_ip:9092 -e zookeeper_address=$local_ip:2181 -e mysql_ip=$local_ip -e key_FaceGo_ip=$local_ip -v /$oss/nasdata:/home/nasdata -e FaceGo_Cluster_ip=$local_ip -e redis_ip=$local_ip -v /etc/localtime:/etc/localtime -p 11011:11011 ocean-socket:1.4.2
fi

sleep 10 
entry_exist=`docker ps -a|grep ocean-entry-http-1.4.2`
if [ -n "$entry_exist" ] ;then
    echo -e "\033[31m >>>>>>>> ocean-entry-http已存在  \033[0m"
else
    echo -e "\033[32m\033[32m >>>>>>>> 安装ocean-entry-http  \033[0m"
    docker load -i ocean-entry-http-1.4.2.tar && docker run -d  --name ocean-entry-http-1.4.2 -e nginx_img_url=$local_ip -e ocean_entry_http_ip=127.0.0.1 -e mysql_ip=$local_ip -e kafka_address=$local_ip:9092 -e zookeeper_address=$local_ip:2181 -e engine_ip=$local_ip -e redis_ip=$local_ip -p 11013:11013 -v /$oss/nasdata:/home/nasdata -v /etc/localtime:/etc/localtime ocean-entry-http:1.4.2
fi

sleep 10
xqp_exist=`docker ps -a|grep xqplatform`
if [ -n "$xqp_exist" ] ;then
    echo -e "\033[31m >>>>>>>> xqplatform已存在  \033[0m"
else
    echo -e "\033[32m\033[32m >>>>>>>> 安装xqplatform  \033[0m"
    sed -i "s/127.0.0.1/$local_ip/g" $dir/ext/xqplatform_config/system.xml
    docker load -i xqplatform.tar && docker run --name xqplatform --env XQ_CONFIG_FILE=/home/xqplatform/config/system.xml -d -v $dir/ext/xqplatform_log:/home/xqplatform/log -v $dir/ext/xqplatform_config:/home/xqplatform/config -v $dir/ext/ssdb_var:/home/ssdb/var -p 12345:12345 -p 12346:12346 -v /etc/localtime:/etc/localtime xqplatform:20190927
fi

sleep 10
facego_exist=`docker ps -a|grep facego-gpu-t4`
if [ -n "$facego_exist" ] ;then
    echo -e "\033[31m >>>>>>>> FaceGo已存在  \033[0m"
else
    echo -e "\033[32m\033[32m >>>>>>>> 安装FaceGo  \033[0m"
    docker load --input facego-gpu-t4-0806.tar && nvidia-docker run -ti -d --name facego-gpu-t4 -p 23011:23011 -p 8100:7100 -p 20000:20000 -p 23000:23000 -v $dir/recogdata/data:/usr/tmp/FaceGo-GPU/data -v $dir/recogdata/facedb:/usr/tmp/FaceGo-GPU/facedb -v $dir/snapdata:/usr/tmp/FaceGo-Snap/data -v $dir/Feature_config:/usr/tmp/FaceGo-Feature/AlgorithmFeature/config -v $dir/Recog_config:/usr/tmp/FaceGo-GPU/facewarehouse_gpu/algosdk/config  -v /etc/localtime:/etc/localtime facego-gpu-t4:0806

fi

echo -e "\033[32m\033[32m >>>>>>>> 安装完成  \033[0m"
  exit 0
  else
  echo -e "\033[31m >>>>>>>> 输入ip格式不正确  \033[0m"
  exit 0
fi
}
uninstall()
{
echo -e "\033[31m >>>>>>>> 开始卸载  \033[0m"
stop
#docker stop `docker ps -a |awk '{print$1}'`  > /dev/null
sleep 10
#docker rm -f `docker ps -a |awk '{print$1}'`  > /dev/null
docker rmi `docker images |awk '{print$3}'`  > /dev/null
echo -e "\033[31m >>>>>>>> 完成卸载  \033[0m"
}

start()
{
echo -e "\033[31m >>>>>>>> 开始启动服务  \033[0m"
mysqlport=3306
mysqlpid=`lsof -i:${mysqlport} |wc -l`
if [ $mysqlpid -eq 0 ];then
docker start mysql-1.4.2 > /dev/null
if [ `lsof -i:${mysqlport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> mysql已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> mysql启动失败  \033[0m"
   fi
fi
sleep 2

facegoport=8100
facegopid=`lsof -i:${facegoport} |wc -l`
if [ $facegopid -eq 0 ];then
docker start facego-gpu-t4 > /dev/null
   if [ `lsof -i:${facegoport} |wc -l` -gt 0 ];then
   echo -e "\\033[32m\033[32m >>>>>>>> FaceGo已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> FaceGo启动失败  \033[0m"
   fi
fi

sleep 2
zkport=2181
zkpid=`lsof -i:${zkport} |wc -l`
if [ $zkpid -eq 0 ];then
docker run -d --rm -p 2181:2181 --name zk1 -v /etc/localtime:/etc/localtime zookeeper > /dev/null
 if [ `lsof -i:${zkport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> zookeeper已启动  \033[0m"
   sleep 10
   else
   echo -e "\033[31m >>>>>>>> zookeeper启动失败  \033[0m"
   fi
fi

kafkaport=9092
kafkapid=`lsof -i:${kafkaport} |wc -l`
if [ $kafkapid -eq 0 ];then
docker run -d --rm --name kafka-1.4.2 -v /etc/localtime:/etc/localtime -p 9092:9092 --link zk1 --env KAFKA_ZOOKEEPER_CONNECT=zk1:2181 --env KAFKA_ADVERTISED_HOST_NAME=172.17.0.3 kafka:1.4.2 > /dev/null
 if [ `lsof -i:${kafkaport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> kafka已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> kafka启动失败  \033[0m"
   fi
fi

sleep 2
redisport=6379
redispid=`lsof -i:${redisport} |wc -l`
if [ $redispid -eq 0 ];then
docker start redis-1.4.2 > /dev/null
if [ `lsof -i:${redisport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> redis已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> redis启动失败  \033[0m"
   fi
fi
sleep 2

oceanport=11006
oceanpid=`lsof -i:${oceanport} |wc -l`
if [ $oceanpid -eq 0 ];then
docker start ocean-1.4.2 > /dev/null
if [ `lsof -i:${oceanport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> ocean已启动   \033[0m"
   else
   echo -e "\033[31m >>>>>>>> ocean启动失败  \033[0m"
   fi
fi
sleep 2

managerport=11007
managerpid=`lsof -i:${managerport} |wc -l`
if [ $managerpid -eq 0 ];then
docker start ocean-manager-1.4.2 > /dev/null
if [ `lsof -i:${managerport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> ocean-manager已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> ocean-manager启动失败  \033[0m"
   fi
fi
sleep 2

xqport=12345
xqpid=`lsof -i:${xqport} |wc -l`
if [ $xqpid -eq 0 ];then
docker start xqplatform > /dev/null
if [ `lsof -i:${xqport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> xqplatform已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> xqplatform启动失败  \033[0m"
   fi
fi
sleep 2

entryport=11013
entrypid=`lsof -i:${entryport} |wc -l`
if [ $entrypid -eq 0 ];then
docker start ocean-entry-http-1.4.2 > /dev/null
if [ `lsof -i:${entryport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> ocean-entry已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> ocean-entry启动失败  \033[0m"
   fi
fi
sleep 2

socketport=11011
socketpid=`lsof -i:${socketport} |wc -l`
if [ $socketpid -eq 0 ];then
docker run  -d --rm --name ocean-socket-1.4.2 -e ocean_socket_ip=127.0.0.1 -e nginx_ip=$local_ip -e kafka_address=$local_ip:9092 -e zookeeper_address=$local_ip:2181 -e mysql_ip=$local_ip -e key_FaceGo_ip=$local_ip -v /$oss/nasdata:/home/nasdata -e FaceGo_Cluster_ip=$local_ip -e redis_ip=$local_ip -v /etc/localtime:/etc/localtime -p 11011:11011 ocean-socket:1.4.2 > /dev/null
if [ `lsof -i:${socketport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> ocean-socket已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> ocean-socket启动失败  \033[0m"
   fi
fi
sleep 2

nginxport=10000
nginxpid=`lsof -i:${nginxport} |wc -l`
if [ $nginxpid -eq 0 ];then
docker start nginx-1.4.2 > /dev/null
 if [ `lsof -i:${nginxport} |wc -l` -gt 0 ];then
   echo -e "\033[32m\033[32m >>>>>>>> nginx已启动  \033[0m"
   else
   echo -e "\033[31m >>>>>>>> nginx启动失败  \033[0m"
   fi
fi
  
echo -e "\033[31m >>>>>>>> 服务启动完成  \033[0m"
}

stop()
{
 echo -e "\033[31m >>>>>>>> 开始停止服务  \033[0m"
 docker stop nginx-1.4.2 > /dev/null
 docker stop ocean-socket-1.4.2 > /dev/null
 docker stop ocean-entry-http-1.4.2 > /dev/null
 docker stop xqplatform > /dev/null
 docker stop ocean-manager-1.4.2 > /dev/null
 docker stop ocean-1.4.2 > /dev/null
 docker stop facego-gpu-t4 > /dev/null
 docker stop mysql-1.4.2 > /dev/null
 docker stop redis-1.4.2 > /dev/null
 docker stop kafka-1.4.2 > /dev/null
 docker stop zk1 > /dev/null
echo -e "\033[31m >>>>>>>> 停止服务结束  \033[0m"
}

case $1 in
    'install')
     install
    ;;
    'uninstall')
     uninstall
    ;;
    'start')
     start
    ;;
    'stop')
     stop
    ;;
    *)
        echo "Usage: $0 {install | uninstall | start | stop}"
        exit 2
    ;;
esac
