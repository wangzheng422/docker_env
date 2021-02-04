# cdh version testing with hadoop, hive, kudu, impala

## steps

```bash
bash run.sh

docker-compose exec datanode1 bash
```

in container

```bash
impala-shell
```

```sql
show databases;

use default;

CREATE TABLE my_first_table
(
  id BIGINT,
  name STRING,
  PRIMARY KEY(id)
)
PARTITION BY HASH PARTITIONS 16
STORED AS KUDU;

insert into my_first_table values( 1, '1');

select * from my_first_table;

```