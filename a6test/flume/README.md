# 效果

本测试，完成filebeat向kafka输出日志，flume从kafka得到json格式的日志，进行etl处理，然后通过kafka，最终sink到hdfs上面去。

## 整体验证流程

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume01.png)

之后用docker-compose.yml启动服务。(已经写好了run.sh，可以直接bash run.sh)

因为yaml已经把相关的服务都逐个启动了，所以我就直接看效果好了。

可以看到kafka上面，已经读取到了log的数据。

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume02.png)

还可以在kafka上面，看到作为flume channel的topic已经有了数据。

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume03.png)

可以在hdfs上面，查看到落地文件

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume04.png)

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume05.png)

在hive中使用命令创建数据表

```sql
create external table log00 partitioned by (day string)
row format serde 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
with serdeproperties ( 'avro.schema.url' = '/flume/.schema/schema.avsc' )
stored as inputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
outputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
location '/flume/log00' ;
```

```sql
alter table log00 add partition ( day = '201807' ) location '/flume/log00/201807' ;
```

请注意，schema文件，是初始化hdfs的时候，就copy进去的，如果建表的时候没有，那么需要先手动copy进去。

在hive中可以查询到这个数据表

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume06.png)

可以在hive中进行查询

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume07.png)


hue中，可以直接进行查询

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/flume08.png)

## 其他测试

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
alter table log00 add partition ( day = '201807' ) location '/flume/log00/201807' ;
```

```sql
create table jsonfy(
'wzh_message' string,
'wzh_timestamp' string,
'wzh_source'   string)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE
location '/flume/log00/201807/';
```