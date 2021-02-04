#!/usr/bin/env bash

set -e
set -x

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname "$SCRIPT")

rm -f tmp/*.jar

# mvn clean install -DskipITs
# mvn clean install -pl debezium-connector-oracle -am -Poracle -DskipITs  -Dinstantclient.dir=/root/work/docker_env/a6test/kafka/dbz-oracle/tmp/instantclient_12_2
# mvn clean install -pl debezium-connector-oracle -am -Poracle -DskipITs  -Dinstantclient.dir=/root/work/docker_env/a6test/kafka/dbz-oracle/tmp/instantclient_11_2

# cp /root/work/debezium/debezium-core/target/debezium-core-0.9.0-SNAPSHOT.jar tmp/
# cp /root/work/debezium/debezium-core/target/debezium-core-0.9.0.Alpha2.jar tmp/
# cp /root/.m2/repository/io/debezium/debezium-core/0.9.0.Alpha2/debezium-core-0.9.0.Alpha2.jar tmp/
cp /root/.m2/repository/io/debezium/debezium-core/0.9.0-SNAPSHOT/debezium-core-0.9.0-SNAPSHOT.jar tmp/


# cp /root/work/debezium/debezium-ddl-parser/target/debezium-ddl-parser-0.9.0-SNAPSHOT.jar tmp/
# cp /root/work/debezium/debezium-ddl-parser/target/debezium-ddl-parser-0.9.0.Alpha2.jar tmp/
# cp /root/.m2/repository/io/debezium/debezium-ddl-parser/0.9.0.Alpha2/debezium-ddl-parser-0.9.0.Alpha2.jar tmp/
cp /root/.m2/repository/io/debezium/debezium-ddl-parser/0.9.0-SNAPSHOT/debezium-ddl-parser-0.9.0-SNAPSHOT.jar tmp/

# cp /root/.m2/repository/io/debezium/debezium-embedded/0.9.0.Alpha2/debezium-embedded-0.9.0.Alpha2.jar tmp/
cp /root/.m2/repository/io/debezium/debezium-embedded/0.9.0-SNAPSHOT/debezium-embedded-0.9.0-SNAPSHOT.jar tmp/

# cp /root/work/debezium-incubator/debezium-connector-oracle/target/debezium-connector-oracle-0.9.0.Alpha2.jar tmp/
# cp /root/work/debezium-incubator/debezium-connector-oracle/target/debezium-connector-oracle-0.9.0-SNAPSHOT.jar tmp/
cp /root/.m2/repository/io/debezium/debezium-connector-oracle/0.9.0-SNAPSHOT/debezium-connector-oracle-0.9.0-SNAPSHOT.jar tmp/

cp /root/.m2/repository/io/debezium/debezium-assembly-descriptors/0.9.0-SNAPSHOT/debezium-assembly-descriptors-0.9.0-SNAPSHOT.jar tmp/

cp /root/.m2/repository/io/debezium/debezium-checkstyle/0.9.0-SNAPSHOT/debezium-checkstyle-0.9.0-SNAPSHOT.jar tmp/

cp /root/.m2/repository/org/antlr/antlr4-runtime/4.7.1/antlr4-runtime-4.7.1.jar tmp/

# cp /root/work/debezium/debezium-microbenchmark/target/debezium-microbenchmark-0.9.0-SNAPSHOT.jar tmp/

# cp /root/work/debezium/debezium-assembly-descriptors/target/debezium-assembly-descriptors-0.9.0-SNAPSHOT.jar tmp/

# cp /root/work/debezium/debezium-embedded/target/debezium-embedded-0.9.0-SNAPSHOT.jar tmp/



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# docker build -f 12.2.Dockerfile -t dbz-oracle-12-2:wzh ${DIR}/
# docker build -f 11.2.Dockerfile -t dbz-oracle-11-2:wzh ${DIR}/
docker build -t dbz-oracle:wzh ${DIR}/