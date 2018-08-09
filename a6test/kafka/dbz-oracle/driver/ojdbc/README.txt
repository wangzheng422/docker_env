OJDBC-FULL.tar.gz - JDBC Thin Driver and Companion JARS
========================================================
This TAR archive (ojdbc-full.tar.gz) contains the 11.2.0.4 release of the Oracle JDBC Thin driver (ojdbc6.jar for JDK8, JDK7, and JDK6. ojdbc6.jar for JDK6), the Universal Connection Pool (ucp.jar) and other companion JARs grouped by category. 

(1) ojdbc6.jar (2,739,670 bytes) - (SHA1 Checksum: a483a046eee2f404d864a6ff5b09dc0e1be3fe6c)
Certified with JDK8, JDK7, and JDK6; 

(2) ojdbc5.jar (2,091,137 bytes)) - (SHA1 Checksum: 5543067223760fc2277fe3f603d8c4630927679c)
For use with JDK1.5; It contains the JDBC driver classes except classes for NLS support in Oracle Object and Collection types. 

(3) ucp.jar (506,301 bytes) - (SHA1 Checksum: 5520b4e492939b477cc9ced90c03bc72710dcaf3)
(Refer MOS note DOC ID 2074693.1) - UCP classes for use with JDK 6 & JDK 7

(4) ojdbc.policy (10,591 bytes) - Sample security policy file for Oracle Database JDBC drivers

=============================
JARs for NLS and XDK support 
=============================
(5) orai18n.jar (1,655,734 bytes) - (SHA1 Checksum: 02ca732c9b5043d39a6b300d190ba0dbce29f3a3) 
NLS classes for use with JDK 1.5, and 1.6. It contains classes for NLS support in Oracle Object and Collection types. This jar file replaces the old nls_charset jar/zip files

(6) xdb6.jar (263,097 bytes) - (SHA1 Checksum: 7604939a619d2f8bd2a02480ab785c2b4a02e3a7)
To use the standard JDBC4.0 java.sql.SQLXML interface with JDBC 11.2.0.4, you need to use xdb6.jar (instead of xdb.jar) from the 11.2.0.4 distribution..

====================================================
JARs for Real Application Clusters(RAC), ADG, or DG 
====================================================

(8) ons.jar (71,830 bytes) - (SHA1 Checksum: 3516a84f4e26caab41d560678bb59076666543f7)
for use by the pure Java client-side Oracle Notification Services (ONS) daemon

(7) simplefan.jar (20,365 bytes) - (SHA1 Checksum: 307a7e203d7e141964158d181ca849d512d7e710)
Java APIs for subscribing to RAC events via ONS; simplefan policy and javadoc

=================
OTHER RESOURCES
=================
Refer to the 11.2 JDBC Developers Guide (https://docs.oracle.com/cd/E11882_01/java.112/e16548/toc.htm) and Universal Connection Pool Developers Guide (https://docs.oracle.com/cd/E11882_01/java.112/e12265/toc.htm) for more details. 
