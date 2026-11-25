-- Sesi 23 · Transfer dengan transaksi (SESSION A)
-- Jalankan SATU PERINTAH sekali jalan dengan Run Statement (Ctrl+Enter / Cmd+Enter), urut dari atas.
-- Session B = file 02-cek-session-b.sql di tab editor lain. Ikuti urutan di README Demo 2.

-- 2.1. Saldo awal kedua rekening
SELECT account_no, status, balance FROM accounts
WHERE account_no IN ('SIM-1000001', 'SIM-1000003') ORDER BY account_no;

-- 2.2. Transfer berhasil: 500.000 dari SIM-1000001 ke SIM-1000003 (4 perintah, 1 transaksi)
UPDATE accounts SET balance = balance - 500000
WHERE account_no = 'SIM-1000001' AND status = 'AKTIF' AND balance >= 500000;

UPDATE accounts SET balance = balance + 500000
WHERE account_no = 'SIM-1000003' AND status = 'AKTIF';

INSERT INTO transactions (account_id, txn_type, category, amount, txn_at, description, ref_no)
VALUES ((SELECT account_id FROM accounts WHERE account_no = 'SIM-1000001'),
        'TRANSFER_KELUAR', 'TRANSFER', 500000, TIMESTAMP '2026-03-31 10:00:00',
        'Transfer ke SIM-1000003', 'REF-SIM-T00001');

INSERT INTO transactions (account_id, txn_type, category, amount, txn_at, description, ref_no)
VALUES ((SELECT account_id FROM accounts WHERE account_no = 'SIM-1000003'),
        'TRANSFER_MASUK', 'TRANSFER', 500000, TIMESTAMP '2026-03-31 10:00:00',
        'Transfer dari SIM-1000001', 'REF-SIM-T00002');

-- 2.3. Cek dari session A (perubahan sendiri sudah terlihat)
SELECT account_no, status, balance FROM accounts
WHERE account_no IN ('SIM-1000001', 'SIM-1000003') ORDER BY account_no;

-- 2.4. (jalankan cek di session B dulu, lalu kembali ke sini) Simpan permanen
COMMIT;

-- 2.5. Transfer gagal: 50.000.000 dari SIM-1000009 (saldo tidak cukup) ke SIM-1000010
--     Sengaja tanpa pengaman "balance >= ..." dan rekening tujuan dikredit duluan.
UPDATE accounts SET balance = balance + 50000000
WHERE account_no = 'SIM-1000010' AND status = 'AKTIF';

UPDATE accounts SET balance = balance - 50000000
WHERE account_no = 'SIM-1000009' AND status = 'AKTIF';

-- 2.6. Perintah kedua ditolak, tapi kredit di perintah pertama masih menggantung. Cek:
SELECT account_no, balance FROM accounts
WHERE account_no IN ('SIM-1000009', 'SIM-1000010') ORDER BY account_no;

-- 2.7. Batalkan semua perubahan sejak COMMIT terakhir, lalu cek lagi
ROLLBACK;

SELECT account_no, balance FROM accounts
WHERE account_no IN ('SIM-1000009', 'SIM-1000010') ORDER BY account_no;
