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
docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "oracledb", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrm", "database.password": "xs", "database.dbname": "ORCLCDB", "database.pdb.name": "ORCLPDB1", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka1:9092", "database.history.kafka.topic": "schema-changes.inventory" } }' \
    http://dbz-connect:8083/connectors

docker-compose exec dbz-connect curl http://dbz-connect:8083/connectors/inventory-connector

docker-compose exec dbz-connect curl -X DELETE http://dbz-connect:8083/connectors/inventory-connector
```

```bash
docker-compose exec -e ORACLE_SID=ORCLCDB oracledb sqlplus /nolog

docker-compose exec oracledb bash

sqlplus debezium/dbz@//localhost:1521/ORCLPDB1

```

``` sql

CREATE TABLE products (
  id NUMBER(4) GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH 101) NOT NULL PRIMARY KEY,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(512),
  weight FLOAT
);
GRANT SELECT ON products to c##xstrm;
ALTER TABLE products ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

INSERT INTO products
  VALUES (NULL,'scooter','Small 2-wheel scooter',3.14);
INSERT INTO products
  VALUES (NULL,'car battery','12V car battery',8.1);
INSERT INTO products
  VALUES (NULL,'12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3',0.8);
INSERT INTO products
  VALUES (NULL,'hammer','12oz carpenter''s hammer',0.75);
INSERT INTO products
  VALUES (NULL,'hammer','14oz carpenter''s hammer',0.875);
INSERT INTO products
  VALUES (NULL,'hammer','16oz carpenter''s hammer',1.0);
INSERT INTO products
  VALUES (NULL,'rocks','box of assorted rocks',5.3);
INSERT INTO products
  VALUES (NULL,'jacket','water resistent black wind breaker',0.1);
INSERT INTO products
  VALUES (NULL,'spare tire','24 inch spare tire',22.2);

-- Create and populate the products on hand using multiple inserts
CREATE TABLE products_on_hand (
  product_id NUMBER(4) NOT NULL PRIMARY KEY,
  quantity NUMBER(4) NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
GRANT SELECT ON products_on_hand to c##xstrm;
ALTER TABLE products_on_hand ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

INSERT INTO products_on_hand VALUES (101,3);
INSERT INTO products_on_hand VALUES (102,8);
INSERT INTO products_on_hand VALUES (103,18);
INSERT INTO products_on_hand VALUES (104,4);
INSERT INTO products_on_hand VALUES (105,5);
INSERT INTO products_on_hand VALUES (106,0);
INSERT INTO products_on_hand VALUES (107,44);
INSERT INTO products_on_hand VALUES (108,2);
INSERT INTO products_on_hand VALUES (109,5);

-- Create some customers ...
CREATE TABLE customers (
  id NUMBER(4) GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH 1001) NOT NULL PRIMARY KEY,
  first_name VARCHAR2(255) NOT NULL,
  last_name VARCHAR2(255) NOT NULL,
  email VARCHAR2(255) NOT NULL UNIQUE
);
GRANT SELECT ON customers to c##xstrm;
ALTER TABLE customers ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

INSERT INTO customers
  VALUES (NULL,'Sally','Thomas','sally.thomas@acme.com');
INSERT INTO customers
  VALUES (NULL,'George','Bailey','gbailey@foobar.com');
INSERT INTO customers
  VALUES (NULL,'Edward','Walker','ed@walker.com');
INSERT INTO customers
  VALUES (NULL,'Anne','Kretchmar','annek@noanswer.org');

-- Create some very simple orders
CREATE TABLE debezium.orders (
  id NUMBER(6) GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH 10001) NOT NULL PRIMARY KEY,
  order_date DATE NOT NULL,
  purchaser NUMBER(4) NOT NULL,
  quantity NUMBER(4) NOT NULL,
  product_id NUMBER(4) NOT NULL,
  FOREIGN KEY (purchaser) REFERENCES customers(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);
GRANT SELECT ON orders to c##xstrm;
ALTER TABLE orders ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

INSERT INTO orders
  VALUES (NULL, '16-JAN-2016', 1001, 1, 102);
INSERT INTO orders
  VALUES (NULL, '17-JAN-2016', 1002, 2, 105);
INSERT INTO orders
  VALUES (NULL, '19-FEB-2016', 1002, 2, 106);
INSERT INTO orders
  VALUES (NULL, '21-FEB-2016', 1003, 1, 107);
```