# teiid docker env

teiid是一个数据库之上的proxy层，他能虚拟vdb，然后将查询分发到后面的数据上面去。

这个测试，是在teiid上面，配置了一个vdb，然后后面有2个pg。

## pg 准备

运行 pg/deploy.sh，自动编译出pg的镜像

## teiid准备

运行 deploy.sh，自动编译出teiid的镜像。

## 运行环境

运行 run.sh，会运行演示环境。

## 测试

找一个db客户端，jdbc:teiid:vdb1@mm://172.19.16.8:31000;version=1

用户名和密码 app / app

```bash
chsh -s /bin/bash jboss

su - jboss

/opt/jboss/wildfly/bin/add-user.sh -u root -p root -e

/opt/jboss/wildfly/bin/add-user.sh -a -u app -p app -e

/opt/jboss/wildfly/bin/jboss-cli.sh --connect --file=/opt/jboss/wildfly/bin/scripts/teiid-standalone-mode-install.cli

/opt/jboss/wildfly/bin/jboss-cli.sh --connect

CREATE SERVER pg1 TYPE 'postgresql-9.4-1201.jdbc41.jar'
    VERSION 'one' FOREIGN DATA WRAPPER postgresql
    OPTIONS (
        "jndi-name" 'java:/pg1-ds'
    );

/opt/jboss/wildfly/bin/jboss-cli.sh --connect --file=/opt/jboss/wildfly/bin/scripts/teiid-domain-mode-install.cli


jdbc:teiid:vdb1@mm://172.19.16.8:31000


docker-compose logs teiid-master

docker-compose exec teiid-master bash

docker-compose exec teiid-master /opt/jboss/wildfly/bin/add-user.sh -u root -p root -e

docker-compose exec teiid-master /opt/jboss/wildfly/bin/add-user.sh -a -u app -p app -e

```

```bash
bug2
```