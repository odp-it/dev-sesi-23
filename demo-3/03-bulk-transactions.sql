-- Sesi 23 · Data bulk untuk latihan optimasi
-- Menambah 1 cabang test, 1 nasabah test, 500 rekening test, dan 200.000 transaksi (Januari-Maret 2026).
-- Data di-generate dengan rumus (bukan acak), jadi hasilnya sama di semua laptop.
-- Jalankan sebagai ALP_DEV dengan Run Script (F5). Waktu test: 10-20 detik.
-- Data Tabungan UMKM asli (rekening SIM-1000001 s.d. SIM-1000015) tidak diubah.

INSERT INTO branches (branch_code, branch_name, city)
VALUES ('KCP-SIM-99', 'Cabang Simulasi Data Uji', 'Jakarta');

INSERT INTO customers (cif_no, full_name, email, phone, segment, branch_id)
VALUES ('CIF-SIM-9999', 'Data Uji Contoh', 'data.uji@example.com', NULL, 'UMKM',
        (SELECT branch_id FROM branches WHERE branch_code = 'KCP-SIM-99'));

-- 500 rekening test SIM-2000001 s.d. SIM-2000500
INSERT INTO accounts (account_no, customer_id, product, balance, status, opened_at)
SELECT 'SIM-' || TO_CHAR(2000000 + LEVEL),
       (SELECT customer_id FROM customers WHERE cif_no = 'CIF-SIM-9999'),
       'TABUNGAN', 0, 'AKTIF', TIMESTAMP '2025-12-01 09:00:00'
FROM dual CONNECT BY LEVEL <= 500;

-- 200.000 transaksi: 2 dari 3 SETOR (PENJUALAN), 1 dari 3 TARIK (BAHAN_BAKU), tersebar 1 Jan - 30 Mar 2026
INSERT INTO transactions (account_id, txn_type, category, amount, txn_at, description, ref_no)
SELECT a.account_id,
       CASE WHEN MOD(g.n, 3) = 0 THEN 'TARIK' ELSE 'SETOR' END,
       CASE WHEN MOD(g.n, 3) = 0 THEN 'BAHAN_BAKU' ELSE 'PENJUALAN' END,
       CASE WHEN MOD(g.n, 3) = 0 THEN (MOD(g.n * 13, 10) + 1) * 50000
            ELSE (MOD(g.n * 37, 40) + 1) * 50000 END,
       TIMESTAMP '2026-01-01 08:00:00' + NUMTODSINTERVAL(MOD(g.n * 7919, 89 * 24 * 60), 'MINUTE'),
       'Data uji',
       'REF-SIM-B' || LPAD(g.n, 6, '0')
FROM (SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 200000) g
JOIN accounts a ON a.account_no = 'SIM-' || TO_CHAR(2000000 + MOD(g.n - 1, 500) + 1);

-- Saldo rekening test = total transaksinya, supaya rekonsiliasi tetap cocok
MERGE INTO accounts a
USING (SELECT account_id,
              SUM(CASE WHEN txn_type = 'SETOR' THEN amount ELSE -amount END) AS saldo
       FROM transactions WHERE ref_no LIKE 'REF-SIM-B%' GROUP BY account_id) s
ON (a.account_id = s.account_id)
WHEN MATCHED THEN UPDATE SET a.balance = s.saldo;

COMMIT;

-- Perbarui statistik tabel supaya optimizer tahu ukuran data yang baru
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSACTIONS');
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'ACCOUNTS');
END;
/

SELECT COUNT(*) AS jumlah_transaksi FROM transactions;
SELECT COUNT(*) AS jumlah_rekening FROM accounts;
