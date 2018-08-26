#!/bin/sh

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
	
	exit;
EOF

sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
    CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_adm_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
	exit;
EOF

sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
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

	exit;
EOF

sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
    CREATE USER debezium IDENTIFIED BY dbz;
	GRANT CONNECT TO debezium;
	GRANT CREATE SESSION TO debezium;
	GRANT CREATE TABLE TO debezium;
	GRANT CREATE SEQUENCE TO debezium;
	ALTER USER debezium QUOTA 100M ON users;
	exit;
EOF

sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
    CREATE TABLESPACE xstream_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_tbs.dbf'
	  SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
	exit;
EOF

sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
    CREATE USER c##xstrm IDENTIFIED BY xs
	  DEFAULT TABLESPACE xstream_tbs
	  QUOTA UNLIMITED ON xstream_tbs;

    GRANT CREATE SESSION TO c##xstrm;
	grant select_catalog_role to c##xstrm;
    GRANT SELECT ON V_\$DATABASE to c##xstrm ;
    GRANT FLASHBACK ANY TABLE TO c##xstrm;

	exit;
EOF


sqlplus c##xstrmadmin/xsa@//localhost:1521/orcl <<- EOF
    DECLARE
	  tables  DBMS_UTILITY.UNCL_ARRAY;
	  schemas DBMS_UTILITY.UNCL_ARRAY;
	BEGIN
	    tables(1)  := NULL;
	    schemas(1) := NULL;
	  DBMS_XSTREAM_ADM.CREATE_OUTBOUND(
	    server_name     =>  'dbzxout',
	    table_names     =>  tables,
	    schema_names    =>  schemas);
	END;
	/
	exit;
EOF

sqlplus sys/oracle@//localhost:1521/orcl as sysdba <<- EOF
    BEGIN
        DBMS_XSTREAM_ADM.ALTER_OUTBOUND(
        server_name  => 'dbzxout',
        connect_user => 'c##xstrm');
    END;
    /
	exit;
EOF
