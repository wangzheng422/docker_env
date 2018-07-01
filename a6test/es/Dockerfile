FROM docker.elastic.co/elasticsearch/elasticsearch-oss:6.2.3

USER root

ENV JQ_VERSION 1.5
ENV JQ_SHA256 c6b3a7d7d3e7b70c6f51b706a3b90bd01833846c54d32ca32f0027f00226ff6d
RUN cd /tmp \
    && curl -o /usr/bin/jq -SL "https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64" \
    && echo "$JQ_SHA256  /usr/bin/jq" | sha256sum -c - \
    && chmod +x /usr/bin/jq \
    && yum install -y net-tools bind-utils

USER elasticsearch

RUN bin/elasticsearch-plugin install repository-hdfs