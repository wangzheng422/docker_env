# dbz for oracle demo steps

## install

follow <https://github.com/debezium/docker-images/tree/master/connect/0.9>

you need to download the driver to ./tmp

then, run deploy.sh

## initialization

follow <https://github.com/debezium/oracle-vagrant-box/blob/master/setup.sh>

run this setup.sh in oracledb

```bash
# as root
docker-compose exec oracledb bash

mkdir -p /opt/oracle/oradata/recovery_area
mkdir -p /opt/oracle/oradata/ORCLCDB
chown -R oracle:dba /opt/oracle

su - oracle

vi setup.sh

bash setup.sh
```

## create kafka connector

```bash
docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "oracledb", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka1:9092",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl.debezium.products,orcl.debezium.cola_markets", "database.tablename.case.insensitive": "true", "database.position.version": "v1" } }' \
    http://dbz-connect:8083/connectors

docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "oracledb", "database.hostname": "oracledb", "database.port": "1521", "database.user": "c##xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "kafka1:9092",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl\\.debezium\\.(.*)", "database.tablename.case.insensitive": "true", "database.position.version": "v1" } }' \
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
CREATE TABLE PRODUCTS (
  id NUMBER(4)   NOT NULL PRIMARY KEY,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(512),
  weight FLOAT
);
GRANT SELECT ON PRODUCTS to c##xstrm;
ALTER TABLE PRODUCTS ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;


INSERT INTO PRODUCTS
  VALUES (1,'scooter','Small 2-wheel scooter',3.14);
commit;


INSERT INTO PRODUCTS
  VALUES (2,'scooter','Small 2-wheel scooter',3.14);
commit;

update PRODUCTS set name='wzh' where id=2;
commit;

update PRODUCTS set id=3 where id=2;
commit;

update PRODUCTS set id=3 where id=3;
commit;

delete from PRODUCTS where id=3;
commit;

INSERT INTO PRODUCTS
  VALUES (3,'scooter','Small 2-wheel scooter',3.14);
commit;


CREATE TABLE cola_markets (
  mkt_id NUMBER PRIMARY KEY,
  name VARCHAR2(32),
  shape SDO_GEOMETRY);
GRANT SELECT ON cola_markets to c##xstrm;
ALTER TABLE cola_markets ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;


INSERT INTO cola_markets VALUES(
  1,
  'cola_a',
  SDO_GEOMETRY(
    2003,  -- two-dimensional polygon
    NULL,
    NULL,
    SDO_ELEM_INFO_ARRAY(1,1003,3), -- one rectangle (1003 = exterior)
    SDO_ORDINATE_ARRAY(1,1, 5,7) -- only 2 points needed to
          -- define rectangle (lower left and upper right) with
          -- Cartesian-coordinate data
  )
);

INSERT INTO cola_markets VALUES(
  2,
  'cola_b',
  SDO_GEOMETRY(
    2003,  -- two-dimensional polygon
    NULL,
    NULL,
    SDO_ELEM_INFO_ARRAY(1,1003,1), -- one polygon (exterior polygon ring)
    SDO_ORDINATE_ARRAY(5,1, 8,1, 8,6, 5,7, 5,1)
  )
);

GRANT SELECT ON CD_LOCATION to c##xstrm;
ALTER TABLE CD_LOCATION ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

## result

now you can see the result in kafka console

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/oracle-dbz.png)

## some url

<http://oradb-srv.wlv.ac.uk/E50529_01/XSTRM/xstrm_xout_man.htm#XSTRM72831>

## other command

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

## blob

```sql

CREATE TABLE test_blob (
  id NUMBER(4)   NOT NULL PRIMARY KEY,
  clob_col  CLOB,
  blob_col  BLOB
);
GRANT SELECT ON test_blob to c##xstrm;
ALTER TABLE test_blob ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

INSERT INTO test_blob
  VALUES (1,to_clob('12345690'),to_blob('12345690'));
commit;

```