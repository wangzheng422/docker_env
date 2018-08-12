

mkdir -p /opt/oracle/oradata/recovery_area
mkdir -p /opt/oracle/oradata/ORCLCDB
chown oracle:dba /opt/oracle


sqlplus /nolog <<- EOF
	CONNECT sys/oracle AS SYSDBA
	alter system set db_recovery_file_dest_size = 5G;
	alter system set db_recovery_file_dest = '/opt/oracle/oradata/recovery_area' scope=spfile;
	alter system set enable_goldengate_replication=true;
	shutdown immediate
	startup mount
	alter database archivelog;
	alter database open;
        -- Should show "Database log mode: Archive Mode"
	archive log list

    CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_adm_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

    CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/xstream_adm_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

    CREATE USER c##xstrmadmin IDENTIFIED BY xsa
	  DEFAULT TABLESPACE xstream_adm_tbs
	  QUOTA UNLIMITED ON xstream_adm_tbs;

    GRANT CREATE SESSION TO c##xstrmadmin ;

    BEGIN
	   DBMS_XSTREAM_AUTH.GRANT_ADMIN_PRIVILEGE(
	      grantee                 => 'c##xstrmadmin',
	      privilege_type          => 'CAPTURE',
	      grant_select_privileges => TRUE
	   );
	END;
	/


    CREATE USER debezium IDENTIFIED BY dbz;
	GRANT CONNECT TO debezium;
	GRANT CREATE SESSION TO debezium;
	GRANT CREATE TABLE TO debezium;
	GRANT CREATE SEQUENCE TO debezium;
	ALTER USER debezium QUOTA 100M ON users;

    CREATE TABLESPACE xstream_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

    CREATE USER c##xstrm IDENTIFIED BY xs
	  DEFAULT TABLESPACE xstream_tbs
	  QUOTA UNLIMITED ON xstream_tbs;


    GRANT CREATE SESSION TO c##xstrm;
    GRANT SELECT ON V_$DATABASE to c##xstrm ;
    GRANT FLASHBACK ANY TABLE TO c##xstrm;



    CONNECT c##xstrmadmin/xsa 

    DECLARE
	  tables  DBMS_UTILITY.UNCL_ARRAY;
	  schemas DBMS_UTILITY.UNCL_ARRAY;
	BEGIN
	    tables(1)  := NULL;
	    schemas(1) := 'debezium';
	  DBMS_XSTREAM_ADM.CREATE_OUTBOUND(
	    server_name     =>  'dbzxout',
	    table_names     =>  tables,
	    schema_names    =>  schemas);
	END;
	/

    CONNECT sys/oracle AS SYSDBA
    BEGIN
        DBMS_XSTREAM_ADM.ALTER_OUTBOUND(
        server_name  => 'dbzxout',
        connect_user => 'c##xstrm');
    END;
    /



EOF

# Create XStream admin user
sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
	CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_adm_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
	exit;
EOF
sqlplus sys/oracle@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
	CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/xstream_adm_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
	exit;
EOF
sqlplus sys/oracle@//localhost:1521/ORCLCDB as sysdba <<- EOF
	CREATE USER c##xstrmadmin IDENTIFIED BY xsa
	  DEFAULT TABLESPACE xstream_adm_tbs
	  QUOTA UNLIMITED ON xstream_adm_tbs
	  CONTAINER=ALL;

	GRANT CREATE SESSION, SET CONTAINER TO c##xstrmadmin CONTAINER=ALL;

	BEGIN
	   DBMS_XSTREAM_AUTH.GRANT_ADMIN_PRIVILEGE(
	      grantee                 => 'c##xstrmadmin',
	      privilege_type          => 'CAPTURE',
	      grant_select_privileges => TRUE
	   );
	END;
	/

	exit;
EOF

# Create test user
sqlplus sys/oracle@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
	CREATE USER debezium IDENTIFIED BY dbz;
	GRANT CONNECT TO debezium;
	GRANT CREATE SESSION TO debezium;
	GRANT CREATE TABLE TO debezium;
	GRANT CREATE SEQUENCE TO debezium;
	ALTER USER debezium QUOTA 100M ON users;

	exit;
EOF

# Create XStream user
sqlplus sys/oracle@//localhost:1521/ORCLCDB as sysdba <<- EOF
  CREATE TABLESPACE xstream_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF
sqlplus sys/oracle@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
  CREATE TABLESPACE xstream_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/xstream_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF
sqlplus sys/oracle@//localhost:1521/ORCLCDB as sysdba <<- EOF
  CREATE USER c##xstrm IDENTIFIED BY xs
	  DEFAULT TABLESPACE xstream_tbs
	  QUOTA UNLIMITED ON xstream_tbs
	  CONTAINER=ALL;

  GRANT CREATE SESSION TO c##xstrm CONTAINER=ALL;
  GRANT SET CONTAINER TO c##xstrm CONTAINER=ALL;
  GRANT SELECT ON V_\$DATABASE to c##xstrm CONTAINER=ALL;
  GRANT FLASHBACK ANY TABLE TO c##xstrm CONTAINER=ALL;
  exit;
EOF

# Create XStream Outbound server
sqlplus c##xstrmadmin/xsa@//localhost:1521/ORCLCDB <<- EOF
	DECLARE
	  tables  DBMS_UTILITY.UNCL_ARRAY;
	  schemas DBMS_UTILITY.UNCL_ARRAY;
	BEGIN
	    tables(1)  := NULL;
	    schemas(1) := 'debezium';
	  DBMS_XSTREAM_ADM.CREATE_OUTBOUND(
	    server_name     =>  'dbzxout',
	    table_names     =>  tables,
	    schema_names    =>  schemas);
	END;
	/

	exit;
EOF

sqlplus sys/oracle@//localhost:1521/ORCLCDB as sysdba <<- EOF
  BEGIN
    DBMS_XSTREAM_ADM.ALTER_OUTBOUND(
      server_name  => 'dbzxout',
      connect_user => 'c##xstrm');
  END;
  /

  exit;
EOF