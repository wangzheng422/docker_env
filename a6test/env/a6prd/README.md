# for a6 prd

docker run --rm wurstmeister/kafka:2.11-0.10.2.2 /opt/kafka/bin/kafka-topics.sh --zookeeper 11.11.157.135:9092 --list

docker-compose exec dbz-connect bin/kafka-topics.sh --zookeeper 11.11.157.135:2181 --list

docker-compose exec dbz-connect bin/kafka-console-consumer.sh --bootstrap-server 11.11.157.135:9092 --topic datalake