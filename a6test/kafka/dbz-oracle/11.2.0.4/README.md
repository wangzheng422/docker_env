# dbz for oracle demo steps

## install

follow <https://github.com/debezium/docker-images/tree/master/connect/0.9>

you need to download the driver to ./tmp

then, run deploy.sh

## initialization

follow <https://github.com/debezium/oracle-vagrant-box/blob/master/setup.sh>

run this setup.sh in oracledb

## create kafka connector

```bash
docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "oracledb", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka1:9092",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl.debezium.products" } }' \
    http://dbz-connect:8083/connectors

docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "oracledb", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrmadmin", "database.password": "xsa", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka1:9092",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl.debezium.products" } }' \
    http://dbz-connect:8083/connectors


docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "oracledb", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka1:9092", "snapshot.mode": "initial_schema_only", "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl.debezium.products" } }' \
    http://dbz-connect:8083/connectors


docker-compose exec dbz-connect curl -X DELETE http://dbz-connect:8083/connectors/inventory-connector

docker-compose logs --no-color dbz-connect > logs
```

## feed some data

follow <https://github.com/debezium/debezium-examples/blob/master/tutorial/debezium-with-oracle-jdbc/init/inventory.sql>

feed this data into database, remember use below sql to connect db and run the sql

```bash
sqlplus debezium/dbz@//localhost:1521/orcl
```

```sql
CREATE TABLE products (
  id NUMBER(4)   NOT NULL PRIMARY KEY,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(512),
  weight FLOAT
);
GRANT SELECT ON products to c##xstrm;
GRANT SELECT ON products to c##xstrmadmin;
ALTER TABLE products ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;


INSERT INTO products
  VALUES (1,'scooter','Small 2-wheel scooter',3.14);
commit;

```

## result

now you can see the result in kafka console

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/oracle-dbz.png)

## some url

<http://oradb-srv.wlv.ac.uk/E50529_01/XSTRM/xstrm_xout_man.htm#XSTRM72831>

## other command

```bash
# as root
docker-compose exec oracledb bash

mkdir -p /opt/oracle/oradata/recovery_area
mkdir -p /opt/oracle/oradata/ORCLCDB
chown -R oracle:dba /opt/oracle

su - oracle

vi setup.sh
```

```sql
CREATE TABLE products (
  id NUMBER(4)   NOT NULL PRIMARY KEY,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(512),
  weight FLOAT
);
GRANT SELECT ON products to c##xstrm;
ALTER TABLE products ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;


INSERT INTO products
  VALUES (1,'scooter','Small 2-wheel scooter',3.14);

SELECT (TIMESTAMP_TO_SCN(max(last_ddl_time))) from all_objects;

select supplemental_log_data_min from v$database;

SELECT SERVER_NAME,
       CAPTURE_NAME
  FROM ALL_XSTREAM_OUTBOUND;
```