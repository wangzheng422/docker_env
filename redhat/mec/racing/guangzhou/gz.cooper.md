```bash

# on 172.29.122.232

cd /root/down/gz
docker load -i centos-7-nginx-rtmp_20191104.tar
docker tag haipenge/centos-7-nginx-rtmp:latest registry.crmi.cn:5021/zhuowang/haipenge/centos-7-nginx-rtmp:latest
docker push registry.crmi.cn:5021/zhuowang/haipenge/centos-7-nginx-rtmp:latest

docker load -i mobilesolider_20191104.tar
docker tag mobilesoldier:v0.2 registry.crmi.cn:5021/zhuowang/mobilesoldier:v0.2 
docker push registry.crmi.cn:5021/zhuowang/mobilesoldier:v0.2 

tar zvxf ocean-1.4.2.tgz
cd ocean-1.4.2/installs

mkdir -p /data/zw

rm -rf /data/zw/lib
tar zxvf lib.tar.gz -C /data/zw/

rm -rf /data/zw/ext
tar zxvf ext.tar.gz -C /data/zw/

rm -rf /data/zw/Feature_config
tar zxvf Feature_config.tar.gz -C /data/zw/

rm -rf /data/zw/Recog_config/
tar -zxvf Recog_config.tar.gz -C /data/zw/

rm -rf /data/zw/recogdata/
tar -zxvf recogdata.tar.gz -C /data/zw/

rm -rf /data/zw/snapdata/
tar -zxvf snapdata.tar.gz -C /data/zw/ 

docker load -i zookeeper-1.4.2.tar 
docker tag zookeeper registry.crmi.cn:5021/zhuowang/zookeeper
docker push registry.crmi.cn:5021/zhuowang/zookeeper

docker load -i kafka-1.4.2.tar
docker tag kafka:1.4.2 registry.crmi.cn:5021/zhuowang/kafka:1.4.2
docker push registry.crmi.cn:5021/zhuowang/kafka:1.4.2

docker load -i redis-1.4.2.tar
docker tag redis:1.4.2 registry.crmi.cn:5021/zhuowang/redis:1.4.2
docker push registry.crmi.cn:5021/zhuowang/redis:1.4.2

docker load -i mysql-1.4.2.tar
docker tag mysql:1.4.2 registry.crmi.cn:5021/zhuowang/mysql:1.4.2
docker push registry.crmi.cn:5021/zhuowang/mysql:1.4.2

docker load -i nginx-1.4.2.tar
docker tag nginx:1.4.2 registry.crmi.cn:5021/zhuowang/nginx:1.4.2
docker push registry.crmi.cn:5021/zhuowang/nginx:1.4.2

docker load -i ocean-1.4.2.tar
docker tag ocean:1.4.2 registry.crmi.cn:5021/zhuowang/ocean:1.4.2
docker push registry.crmi.cn:5021/zhuowang/ocean:1.4.2

docker load -i ocean-manager-1.4.2.tar 
docker tag ocean-manager:1.4.2 registry.crmi.cn:5021/zhuowang/ocean-manager:1.4.2
docker push registry.crmi.cn:5021/zhuowang/ocean-manager:1.4.2

docker load -i ocean-socket-1.4.2.tar
docker tag ocean-socket:1.4.2 registry.crmi.cn:5021/zhuowang/ocean-socket:1.4.2
docker push registry.crmi.cn:5021/zhuowang/ocean-socket:1.4.2

docker load -i ocean-entry-http-1.4.2.tar
docker tag ocean-entry-http:1.4.2 registry.crmi.cn:5021/zhuowang/ocean-entry-http:1.4.2
docker push registry.crmi.cn:5021/zhuowang/ocean-entry-http:1.4.2

docker load -i xqplatform.tar 
docker tag xqplatform:20190927 registry.crmi.cn:5021/zhuowang/xqplatform:20190927
docker push registry.crmi.cn:5021/zhuowang/xqplatform:20190927

docker load -i facego-gpu-t4-0806.tar
docker tag facego-gpu-t4:0806 registry.crmi.cn:5021/zhuowang/facego-gpu-t4:0806
docker push registry.crmi.cn:5021/zhuowang/facego-gpu-t4:0806


# sed -i "s/127.0.0.1/$local_ip/g" $dir/ext/xqplatform_config/system.xml

mkdir -p /data/zw/mysql /data/zw/nasdata /data/zw/nasdata_2 /data/zw/nasdata

oc new-project zhuowang
oc create serviceaccount mysvcacct -n zhuowang
oc adm policy add-scc-to-user privileged -z mysvcacct -n zhuowang
oc adm policy add-scc-to-user anyuid -z mysvcacct -n zhuowang

oc apply -f zhuowang-dp.yaml

oc delete -f zhuowang-dp.yaml

```