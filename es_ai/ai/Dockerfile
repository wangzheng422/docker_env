FROM ubuntu:wzh

RUN mkdir -p /app && wget -qO- https://github.com/o19s/elasticsearch-learning-to-rank/archive/v1.1.0.tar.gz  | tar zxvf - -C /app --strip 1 && apt-get install -y python3-pip && pip3 install elasticsearch && cd /app/demo && python3 prepare.py 

COPY src/demo/* /app/demo/

WORKDIR /app


