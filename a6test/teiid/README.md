# teiid docker env

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

docker-compose logs teiid-master

```







/opt/jboss/wildfly/bin/jboss-cli.sh --connect --file=/opt/jboss/wildfly/bin/scripts/teiid-domain-mode-install.cli


jdbc:teiid:vdb1@mm://127.0.0.1:31000

```