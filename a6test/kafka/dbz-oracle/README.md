# dbz for oracle demo steps

## install

follow <https://github.com/debezium/docker-images/tree/master/connect/0.9>

you need to download the driver to ./tmp

then, run deploy.sh

## initialization

follow <https://github.com/debezium/oracle-vagrant-box/blob/master/setup.sh>

run this setup.sh in oracledb

## feed some data

follow <https://github.com/debezium/debezium-examples/blob/master/tutorial/debezium-with-oracle-jdbc/init/inventory.sql>

feed this data into database, remember use below sql to connect db and run the sql

```sql
sqlplus debezium/dbz@//localhost:1521/ORCLPDB1
```

## result

now you can see the result in kafka console

![alt text](https://github.com/wangzheng422/docker_env/raw/master/a6test/docs/oracle-dbz.png)