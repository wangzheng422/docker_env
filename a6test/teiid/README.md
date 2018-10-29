# teiid docker env

```bash
/opt/jboss/wildfly/bin/add-user.sh -u root -p root -e

/opt/jboss/wildfly/bin/jboss-cli.sh --connect --file=/opt/jboss/wildfly/bin/scripts/teiid-standalone-mode-install.cli


/opt/jboss/wildfly/bin/jboss-cli.sh --connect --file=/opt/jboss/wildfly/bin/scripts/teiid-domain-mode-install.cli

```