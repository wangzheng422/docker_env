FROM hadoop:wzh

RUN apt-get update && apt-get -y install wget curl && \
cd /etc/apt/sources.list.d && \
wget -qO - https://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh/archive.key | apt-key add - && \
wget http://archive.cloudera.com/kudu/ubuntu/xenial/amd64/kudu/cloudera.list && \
apt-get update && \
apt-get -y install kudu kudu-master kudu-tserver libkuduclient0 libkuduclient-dev

# VOLUME /var/lib/kudu/master /var/lib/kudu/tserver

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8050 8051 7050 7051
CMD ["help"]