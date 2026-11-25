-- Sesi 23 · Izin membaca statistik eksekusi (DBMS_XPLAN.DISPLAY_CURSOR) untuk ALP_DEV
-- Jalankan SEKALI sebagai SYSDBA di dalam container:
--   docker cp setup/02-grant-plan-stats.sql oracle-alp:/tmp/02-grant-plan-stats.sql
--   docker exec -it oracle-alp sqlplus / as sysdba "@/tmp/02-grant-plan-stats.sql"
-- Hanya untuk database latihan di laptop. Di database kantor, izin seperti ini diatur DBA.
SET FEEDBACK ON
WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION SET CONTAINER = FREEPDB1;

GRANT SELECT ON sys.v_$session TO alp_dev;
GRANT SELECT ON sys.v_$sql TO alp_dev;
GRANT SELECT ON sys.v_$sql_plan TO alp_dev;
GRANT SELECT ON sys.v_$sql_plan_statistics_all TO alp_dev;

PROMPT Izin statistik plan untuk ALP_DEV selesai.
EXIT
