FROM teiid:wzh

RUN $JBOSS_HOME/add-user.sh -u root -p root -e

# Run Teiid server and bind to all interface
CMD ["/bin/sh", "-c", "$JBOSS_HOME/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0"]
