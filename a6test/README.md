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

flume

```bash
hadoop fs -mkdir /flume/.schema/
hadoop fs -copyFromLocal /opt/schema/schema.avsc /flume/.schema/
```

```sql
create external table log00 partitioned by (day string)
row format serde 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
with serdeproperties ( 'avro.schema.url' = '/flume/.schema/schema.avsc' )
stored as inputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
outputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
location '/flume/log00' ;
```

```sql
create external table log00 
row format serde 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
with serdeproperties ( 'avro.schema.url' = '/flume/.schema/schema.avsc' )
stored as inputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
outputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
location '/flume/log00/201807/' ;
```

```sql
alter table log00 add partition ( day = '2018072321' ) location '/flume/log00/2018072321' ;
```