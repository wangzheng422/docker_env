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

docker-compose exec dbz-connect bash
bin/kafka-topics.sh --zookeeper zoo1:2181 --list
bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092 --topic oracledb.DEBEZIUM.CD_LOCATION
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

```sql
COLUMN CAPTURE_NAME HEADING 'Capture|Name' FORMAT A15
COLUMN CREATE_MESSAGE HEADING 'Last LCR|Create Time'
COLUMN ENQUEUE_MESSAGE HEADING 'Last|Enqueue Time'

SELECT CAPTURE_NAME,
       TO_CHAR(CAPTURE_MESSAGE_CREATE_TIME, 'HH24:MI:SS MM/DD/YY') CREATE_MESSAGE,
       TO_CHAR(ENQUEUE_MESSAGE_CREATE_TIME, 'HH24:MI:SS MM/DD/YY') ENQUEUE_MESSAGE
  FROM V$STREAMS_CAPTURE;

declare
tracking_label  VARCHAR2(15);
BEGIN
	dbms_streams_adm.set_message_tracking(
    tracking_label => 'wzh_demo',
    actions        => DBMS_STREAMS_ADM.ACTION_MEMORY);

  DBMS_CAPTURE_ADM.SET_PARAMETER(
    capture_name => 'CAP$_DBZXOUT_1',
    parameter => 'message_tracking_frequency',
    value  => '1'
  );
end;
/



select component_name,
     component_type,
     action,
     object_owner,
     object_name,
     command_type
from V$STREAMS_MESSAGE_TRACKING
where tracking_label='wzh_demo'
order by timestamp

select * from V$STREAMS_MESSAGE_TRACKING

COLUMN ACTION HEADING 'XStream Component' FORMAT A30
COLUMN SID HEADING 'Session ID' FORMAT 99999
COLUMN SERIAL# HEADING 'Session|Serial|Number' FORMAT 99999999
COLUMN PROCESS HEADING 'Operating System|Process ID' FORMAT A17
COLUMN PROCESS_NAME HEADING 'XStream|Program|Name' FORMAT A7
 
SELECT /*+PARAM('_module_action_old_length',0)*/ ACTION,
       SID,
       SERIAL#,
       PROCESS,
       SUBSTR(PROGRAM,INSTR(PROGRAM,'(')+1,4) PROCESS_NAME
  FROM V$SESSION
  WHERE MODULE ='XStream';

COLUMN SERVER_NAME HEADING 'Outbound|Server|Name' FORMAT A10
COLUMN CONNECT_USER HEADING 'Connect|User' FORMAT A10
COLUMN CAPTURE_USER HEADING 'Capture|User' FORMAT A10
COLUMN CAPTURE_NAME HEADING 'Capture|Process|Name' FORMAT A12
COLUMN SOURCE_DATABASE HEADING 'Source|Database' FORMAT A11
COLUMN QUEUE_OWNER HEADING 'Queue|Owner' FORMAT A10
COLUMN QUEUE_NAME HEADING 'Queue|Name' FORMAT A10

SELECT SERVER_NAME, 
       CONNECT_USER, 
       CAPTURE_USER, 
       CAPTURE_NAME,
       SOURCE_DATABASE,
       QUEUE_OWNER,
       QUEUE_NAME
  FROM ALL_XSTREAM_OUTBOUND;


COLUMN APPLY_NAME HEADING 'Outbound Server|Name' FORMAT A15
COLUMN STATUS HEADING 'Status' FORMAT A8
COLUMN ERROR_NUMBER HEADING 'Error Number' FORMAT 9999999
COLUMN ERROR_MESSAGE HEADING 'Error Message' FORMAT A40

SELECT APPLY_NAME, 
       STATUS,
       ERROR_NUMBER,
       ERROR_MESSAGE
  FROM DBA_APPLY
  WHERE PURPOSE = 'XStream Out';


COLUMN SERVER_NAME HEADING 'Outbound|Server|Name' FORMAT A8
COLUMN TOTAL_TRANSACTIONS_SENT HEADING 'Total|Trans|Sent' FORMAT 9999999
COLUMN TOTAL_MESSAGES_SENT HEADING 'Total|LCRs|Sent' FORMAT 9999999999
COLUMN BYTES_SENT HEADING 'Total|MB|Sent' FORMAT 99999999999999
COLUMN ELAPSED_SEND_TIME HEADING 'Time|Sending|LCRs|(in seconds)' FORMAT 99999999
COLUMN LAST_SENT_MESSAGE_NUMBER HEADING 'Last|Sent|Message|Number' FORMAT 99999999
COLUMN LAST_SENT_MESSAGE_CREATE_TIME HEADING 'Last|Sent|Message|Creation|Time' FORMAT A9
 
SELECT SERVER_NAME,
       TOTAL_TRANSACTIONS_SENT,
       TOTAL_MESSAGES_SENT,
       (BYTES_SENT/1024)/1024 BYTES_SENT,
       (ELAPSED_SEND_TIME/100) ELAPSED_SEND_TIME,
       LAST_SENT_MESSAGE_NUMBER,
       TO_CHAR(LAST_SENT_MESSAGE_CREATE_TIME,'HH24:MI:SS MM/DD/YY') 
          LAST_SENT_MESSAGE_CREATE_TIME
  FROM V$XSTREAM_OUTBOUND_SERVER;
```