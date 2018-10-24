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

CREATE TABLE my_first_table
(
  id BIGINT,
  name STRING,
  PRIMARY KEY(id)
)
STORED AS KUDU;


```