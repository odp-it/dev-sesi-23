-- Sesi 23 · Execution plan sebelum dan sesudah index
-- Jalankan per perintah dengan Run Statement, urut dari atas. Hasil DBMS_XPLAN tampil sebagai tabel di Query Result.
-- Query yang dioptimasi: mutasi satu rekening dalam satu bulan (dipakai lagi di Demo 4).
-- P3 dan P6 butuh izin dari setup/02-grant-plan-stats.sql (README langkah 3.0).

-- P1. Pastikan index IDX_TXN_ACCOUNT_AT belum ada (expected: hanya PK_TRANSACTIONS dan UQ_TRANSACTIONS_REF)
SELECT index_name, column_name, column_position
FROM user_ind_columns WHERE table_name = 'TRANSACTIONS' ORDER BY index_name, column_position;

-- P2. Plan SEBELUM index: perkiraan optimizer (query belum dijalankan)
EXPLAIN PLAN SET STATEMENT_ID = 'sebelum' FOR
SELECT txn_at, txn_type, category, amount, ref_no
FROM transactions
WHERE account_id = 4
  AND txn_at >= TIMESTAMP '2026-02-01 00:00:00'
  AND txn_at <  TIMESTAMP '2026-03-01 00:00:00'
ORDER BY txn_at;

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'sebelum', 'TYPICAL'));

-- P3. Jalankan query SEBELUM index sambil merekam statistik, lalu lihat blok data (Buffers) yang dibaca
SELECT /*+ GATHER_PLAN_STATISTICS */ /* mutasi-sebelum */ txn_at, txn_type, category, amount, ref_no
FROM transactions
WHERE account_id = 4
  AND txn_at >= TIMESTAMP '2026-02-01 00:00:00'
  AND txn_at <  TIMESTAMP '2026-03-01 00:00:00'
ORDER BY txn_at;

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT MAX(sql_id) FROM v$sql
   WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS */ /* mutasi-sebelum */%'),
  NULL, 'ALLSTATS LAST'));

-- P4. Buat index composite: kolom filter "=" dulu, kolom rentang sesudahnya
CREATE INDEX idx_txn_account_at ON transactions (account_id, txn_at);

-- P5. Plan SESUDAH index (query sama persis)
EXPLAIN PLAN SET STATEMENT_ID = 'sesudah' FOR
SELECT txn_at, txn_type, category, amount, ref_no
FROM transactions
WHERE account_id = 4
  AND txn_at >= TIMESTAMP '2026-02-01 00:00:00'
  AND txn_at <  TIMESTAMP '2026-03-01 00:00:00'
ORDER BY txn_at;

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'sesudah', 'TYPICAL'));

-- P6. Jalankan query SESUDAH index, lihat Buffers
SELECT /*+ GATHER_PLAN_STATISTICS */ /* mutasi-sesudah */ txn_at, txn_type, category, amount, ref_no
FROM transactions
WHERE account_id = 4
  AND txn_at >= TIMESTAMP '2026-02-01 00:00:00'
  AND txn_at <  TIMESTAMP '2026-03-01 00:00:00'
ORDER BY txn_at;

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT MAX(sql_id) FROM v$sql
   WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS */ /* mutasi-sesudah */%'),
  NULL, 'ALLSTATS LAST'));

-- P7. Index tidak terpakai: filter hanya di kolom kedua index (txn_at), kolom pertama tidak disebut
EXPLAIN PLAN SET STATEMENT_ID = 'kolom-kedua' FOR
SELECT txn_at, amount FROM transactions
WHERE txn_at >= TIMESTAMP '2026-03-30 00:00:00';

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'kolom-kedua', 'BASIC +COST +ROWS +PREDICATE'));

-- P8. Index tidak terpakai: fungsi membungkus kolom index
EXPLAIN PLAN SET STATEMENT_ID = 'fungsi' FOR
SELECT txn_at, amount FROM transactions
WHERE TO_CHAR(account_id) = '4';

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'fungsi', 'BASIC +COST +ROWS +PREDICATE'));
