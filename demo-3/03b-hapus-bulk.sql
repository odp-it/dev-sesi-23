-- Sesi 23 · Hapus data bulk (opsional, setelah Demo 3 selesai)
-- Mengembalikan data ke kondisi Tabungan UMKM (15 rekening asli). Index IDX_TXN_ACCOUNT_AT tetap ada.
-- Jalankan sebagai ALP_DEV dengan Run Script (F5).

DELETE FROM transactions WHERE ref_no LIKE 'REF-SIM-B%';
DELETE FROM accounts WHERE account_no BETWEEN 'SIM-2000001' AND 'SIM-2000500';
DELETE FROM customers WHERE cif_no = 'CIF-SIM-9999';
DELETE FROM branches WHERE branch_code = 'KCP-SIM-99';
COMMIT;

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSACTIONS');
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'ACCOUNTS');
END;
/

SELECT COUNT(*) AS jumlah_transaksi FROM transactions;
