# 效果

for elastic search

sysctl -w vm.max_map_count=262144

## 整体验证流程

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16_9-53-14.png)

之后用docker-compose.yml启动服务。

用kafka/mysql.sql来导入一点数据

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16-17_39_21.png)

启动以后，使用命令创建kafka-connect, mysql source，读取数据库

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{"name":"mysql-source","config":{"connector.class":"io.confluent.connect.jdbc.JdbcSourceConnector","tasks.max":"1","connection.url":"jdbc:mysql://mysqldb:3306/wzh_db?verifyServerCertificate=false&useSSL=true&requireSSL=true","connection.user":"root","connection.password":"root","flush.size":"1","name":"mysql-source","table.whitelist":"wzh_tb","mode":"incrementing","incrementing.column.name":"id","topic.prefix":"wzh-mysql-"}}' \
    http://kafka-connect:8083/connectors
```

然后创建kafka-connect, hdfs-sink，写入到hdfs

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{"name":"hdfs-sink","config":{"connector.class":"io.confluent.connect.hdfs.HdfsSinkConnector","tasks.max":"1","topics":"wzh-mysql-wzh_tb","hdfs.url":"hdfs://namenode:9000","flush.size":"1","name":"hdfs-sink","hive.integration":"true","hive.metastore.uris":"thrift://namenode:9083","schema.compatibility":"BACKWARD"}}' \
    http://kafka-connect:8083/connectors
```

可以看到kafka上面，已经读取到了mysql的数据

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16-17_36_43.png)

系统也读取到了数据表的结构信息

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16-17_37_10.png)

查看kafka-connect状态，都正常

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16-17_37_44.png)

可以在hdfs上面，查看到落地文件

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16-17_38_26.png)

在hive中可以查询到这个数据表

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/worddav1b2e6c7f7640f96aa933b8edb45a35f2.png)

hue中，可以直接进行查询

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/image2018-7-16-17_36_2.png)

```bash
docker exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{  "name": "hdfs-sink",  "config": {    "connector.class": "io.confluent.connect.hdfs.HdfsSinkConnector",    "tasks.max": "1",    "topics": "wzh_filebeat",    "hdfs.url": "hdfs://namenode:9000",    "flush.size": "3",    "name": "hdfs-sink",    "hive.integration": "true",    "hive.metastore.uris": "thrift://namenode:9083",    "schema.compatibility": "BACKWARD"  } }' \
    http://kafka-connect:8083/connectors
```

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{     "name": "hdfs-sink",     "config": {         "connector.class": "io.confluent.connect.hdfs.HdfsSinkConnector",         "tasks.max": "1",         "topics": "wzh_filebeat",         "hdfs.url": "hdfs://namenode:9000",         "flush.size": "1",         "name": "hdfs-sink",         "key.converter": "org.apache.kafka.connect.storage.StringConverter",         "key.converter.schemas.enable": "false",         "value.converter": "org.apache.kafka.connect.json.JsonConverter",         "value.converter.schemas.enable": "false"  } }' \
    http://kafka-connect:8083/connectors
```

## 其他测试

### file source

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{"name":"local-file-source","config":{"connector.class":"FileStreamSource","tasks.max":"1","topic":"wzh_file_log","name":"local-file-source","file":"/mnt/auth.log"}}' \
    http://kafka-connect:8083/connectors
```

hdfs sink

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{"name":"hdfs-sink","config":{"connector.class":"io.confluent.connect.hdfs.HdfsSinkConnector","tasks.max":"1","topics":"wzh_file_log","hdfs.url":"hdfs://namenode:9000","flush.size":"1","name":"hdfs-sink","hive.integration":"true","hive.metastore.uris":"thrift://namenode:9083","schema.compatibility":"BACKWARD"}}' \
    http://kafka-connect:8083/connectors
```

``` bash
 docker-compose exec kafka-connect curl -s -X GET http://kafka-connect:8083/connectors/hdfs-sink/status
```

### mysql source

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{"name":"mysql-source","config":{"connector.class":"io.confluent.connect.jdbc.JdbcSourceConnector","tasks.max":"1","connection.url":"jdbc:mysql://mysqldb:3306/wzh_db?verifyServerCertificate=false&useSSL=true&requireSSL=true","connection.user":"root","connection.password":"root","flush.size":"1","name":"mysql-source","table.whitelist":"wzh_tb","mode":"incrementing","incrementing.column.name":"id","topic.prefix":"wzh-mysql-"}}' \
    http://kafka-connect:8083/connectors
```

hdfs sink

``` bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{"name":"hdfs-sink","config":{"connector.class":"io.confluent.connect.hdfs.HdfsSinkConnector","tasks.max":"1","topics":"wzh-mysql-wzh_tb","hdfs.url":"hdfs://namenode:9000","flush.size":"1","name":"hdfs-sink","hive.integration":"true","hive.metastore.uris":"thrift://namenode:9083","schema.compatibility":"BACKWARD"}}' \
    http://kafka-connect:8083/connectors
```

oracle source

```bash
docker-compose exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "server1", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrm", "database.password": "xsa", "database.dbname": "ORCLCDB", "database.pdb.name": "ORCLPDB1", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka:9092", "database.history.kafka.topic": "schema-changes.inventory" } }' \
    http://kafka-connect:8083/connectors
```
