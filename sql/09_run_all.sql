-- Déploiement complet
-- À lancer avec un compte DBA pour 01_init_oracle.sql.

SET ECHO ON;
SET FEEDBACK ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

@@01_init_oracle.sql

CONNECT CYTECH_ADMIN/admin123

@@02_schema.sql
@@03_indexes.sql
@@04_views.sql
@@05_plsql.sql
@@06_bddr.sql
@@07_test_data.sql
@@08_performance_tests.sql

SET ECHO OFF;
