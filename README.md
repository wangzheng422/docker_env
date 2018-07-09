# docker_env


docker exec kafka-connect curl -X POST -H "Content-Type: application/json" \
    --data '{  "name": "hdfs-sink",  "config": {    "connector.class": "io.confluent.connect.hdfs.HdfsSinkConnector",    "tasks.max": "1",    "topics": "wzh_filebeat",    "hdfs.url": "hdfs://namenode:9000",    "flush.size": "3",    "name": "hdfs-sink",    "hive.integration": "true",    "hive.metastore.uris": "thrift://namenode:9083",    "schema.compatibility": "BACKWARD"  } }' \
    http://kafka-connect:8083/connectors