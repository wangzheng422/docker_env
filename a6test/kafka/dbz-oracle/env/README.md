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
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "ordb", "database.hostname": "10.88.104.236", "database.port": "1521", "database.user": "xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "10.88.104.225:9292",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl.EPDM.CD_LOCATION,orcl.META_DM.UA_ORG", "database.tablename.case.insensitive": "true", "database.position.version": "v1" } }' \
    http://dbz-connect:8083/connectors

docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "ordb", "database.hostname": "10.88.104.236", "database.port": "1521", "database.user": "xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "10.88.104.225:9292",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl.epdm.cd_location,orcl.meta_dm.ua_org", "database.tablename.case.insensitive": "false", "database.position.version": "v1" } }' \
    http://dbz-connect:8083/connectors

docker-compose exec dbz-connect curl -X POST -H "Content-Type: application/json" \
    --data '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.oracle.OracleConnector", "tasks.max": "1", "database.server.name": "ordb", "database.hostname": "10.88.104.236", "database.port": "1521", "database.user": "xstrm", "database.password": "xs", "database.dbname": "orcl", "database.out.server.name": "dbzxout", "database.history.kafka.bootstrap.servers": "10.88.104.225:9292",  "database.history.kafka.topic": "schema-changes.inventory" , "table.whitelist":"orcl\\.epdm\\.(.*)", "database.tablename.case.insensitive": "true", "database.position.version": "v1" } }' \
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
ALTER TABLE products ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;


INSERT INTO products
  VALUES (1,'scooter','Small 2-wheel scooter',3.14);
commit;


INSERT INTO products
  VALUES (2,'scooter','Small 2-wheel scooter',3.14);
commit;

update products set name='wzh' where id=2;
commit;

update products set id=3 where id=2;
commit;

update products set id=3 where id=3;
commit;

delete from products where id=3;
commit;

INSERT INTO products
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

## null point

```sql

create table EPDM.CD_LOCATION
(
  location_id          VARCHAR2(32) not null,
  coordinate_system_id VARCHAR2(32) not null,
  entity_id            VARCHAR2(32) not null,
  entity_type          NVARCHAR2(32) not null,
  entity_location_type NVARCHAR2(32) not null,
  phase                NVARCHAR2(32) not null,
  geo_offset_east      NUMBER(12,3),
  geo_offset_north     NUMBER(12,3),
  elevation            NUMBER(7,2),
  org_id               VARCHAR2(32),
  measure_date         DATE,
  remarks              NVARCHAR2(2000),
  create_date          DATE,
  create_user_id       NVARCHAR2(64),
  create_app_id        NVARCHAR2(64),
  update_date          DATE,
  update_user_id       NVARCHAR2(64),
  check_date           DATE,
  check_user_id        NVARCHAR2(64),
  bsflag               NVARCHAR2(1),
  send_indicate        NVARCHAR2(32),
  create_org_id        NVARCHAR2(32),
  update_org_id        NVARCHAR2(32),
  source               NVARCHAR2(64),
  original_elevation   NUMBER(7,2)
)

insert into EPDM.CD_LOCATION
  (LOCATION_ID,
   COORDINATE_SYSTEM_ID,
   ENTITY_ID,
   ENTITY_TYPE,
   ENTITY_LOCATION_TYPE,
   PHASE,
   GEO_OFFSET_EAST,
   GEO_OFFSET_NORTH,
   ELEVATION,
   ORG_ID,
   MEASURE_DATE,
   REMARKS,
   CREATE_DATE,
   CREATE_USER_ID,
   CREATE_APP_ID,
   UPDATE_DATE,
   UPDATE_USER_ID,
   CHECK_DATE,
   CHECK_USER_ID,
   BSFLAG,
   SEND_INDICATE,
   CREATE_ORG_ID,
   UPDATE_ORG_ID,
   SOURCE,
   ORIGINAL_ELEVATION
   )
values
  ('JD3diI8ssrQpx85327wAHBR0d8fzxk21',
   'Exioao90Kldoz3KdiknkIOlkdaKIL000',
   'JD7TKoykKm',
   'ALBzMoOtXEfHUPHWloXYs5WKezqFhYpu',
   'cW3ZsilstZOzMjjhB2jnK3LhxXgP5Xsl',
   'OXDuNs5ErVSydCnwcqyvOu2yYIFi6gAf',
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null,
   null
 );

```