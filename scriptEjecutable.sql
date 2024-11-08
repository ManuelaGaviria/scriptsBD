/*
connect system/1234

show con_name

ALTER SESSION SET CONTAINER=CDB$ROOT;
ALTER DATABASE OPEN;

DROP TABLESPACE ts_bdAcademy INCLUDING CONTENTS and DATAFILES;
    
CREATE TABLESPACE ts_bdAcademy LOGGING
DATAFILE 'C:\BD\pruebabd2\DF_DBAcademy.dbf' size 500M
extent management local segment space management auto;
 
alter session set "_ORACLE_SCRIPT"=true;
 
drop user us_dbAcademy cascade;
    
CREATE user us_dbAcademy profile default
identified by 1234
default tablespace ts_bdAcademy
temporary tablespace temp
account unlock;	 

--privilegios
grant connect, resource,dba to us_dbAcademy;

connect us_dbAcademy/1234

show user
*/


start C:\Users\ASUS\Documents\GitHub\scriptsBD\scripts\DBAcademy.sql
start C:\Users\ASUS\Documents\GitHub\scriptsBD\scripts\functionsProcedures.sql
start C:\Users\ASUS\Documents\GitHub\scriptsBD\scripts\packages.sql

