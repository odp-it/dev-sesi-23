-- Sesi 23 · Cek dari SESSION B
-- Buka file ini di tab editor terpisah dan pasang koneksi ALP_DEV @ FREEPDB1.
-- Setiap tab worksheet SQL Developer for VS Code memakai session database sendiri (status bar: "Dedicated").
-- Jalankan dengan Run Statement setiap kali README memintanya.

SELECT account_no, status, balance FROM accounts
WHERE account_no IN ('SIM-1000001', 'SIM-1000003') ORDER BY account_no;

SELECT ref_no, txn_type, amount FROM transactions
WHERE ref_no LIKE 'REF-SIM-T%' ORDER BY ref_no;
