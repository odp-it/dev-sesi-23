-- Sesi 23 · Query laporan & validasi
-- Tulis satu query di bawah setiap soal, jalankan dengan Run Statement (Ctrl+Enter / Cmd+Enter),
-- lalu cocokkan kolom dan jumlah barisnya dengan keterangan "Expected".
-- Jalankan SEBELUM data bulk (Demo 3), supaya angkanya sama dengan expected.

-- R1 (contoh). Saldo per cabang: jumlah nasabah, jumlah rekening, total saldo
-- Expected: kolom branch_code, branch_name, jumlah_nasabah, jumlah_rekening, total_saldo · 3 baris
SELECT b.branch_code, b.branch_name,
       COUNT(DISTINCT c.customer_id) AS jumlah_nasabah,
       COUNT(a.account_id)           AS jumlah_rekening,
       SUM(a.balance)                AS total_saldo
FROM branches b
JOIN customers c ON c.branch_id = b.branch_id
JOIN accounts a  ON a.customer_id = c.customer_id
GROUP BY b.branch_code, b.branch_name
ORDER BY b.branch_code;

-- R1b. Ubah R1 supaya nasabah tanpa rekening tetap terhitung di jumlah_nasabah
-- Expected: 3 baris · jumlah_nasabah tiap cabang 4
-- Petunjuk: JOIN mana yang membuang nasabah tanpa pasangan?


-- R2. Mutasi rekening SIM-1000004 per bulan: uang masuk, uang keluar, jumlah transaksi
-- Expected: kolom account_no, bulan (YYYY-MM), uang_masuk, uang_keluar, jumlah_transaksi · 3 baris
-- Petunjuk: uang masuk = SETOR + TRANSFER_MASUK; SUM(CASE WHEN ... THEN amount ELSE 0 END)


-- R3. Nasabah yang belum pernah bertransaksi (termasuk yang belum punya rekening)
-- Expected: kolom cif_no, full_name, jumlah_rekening · 2 baris
-- Petunjuk: LEFT JOIN customers -> accounts -> transactions, lalu HAVING COUNT(t.txn_id) = 0


-- R4. Arus kas nasabah UMKM per bulan per kategori, kategori TRANSFER tidak dihitung
-- Expected: kolom bulan, category, masuk, keluar · 12 baris · urut bulan lalu kategori


-- R5. Validasi: rekening berstatus selain AKTIF yang masih punya transaksi sejak 1 Maret 2026
-- Expected: kolom account_no, status, transaksi_maret · 0 baris (data bersih)
-- Petunjuk: WHERE ... AND EXISTS (SELECT 1 FROM transactions t WHERE ...)


-- R6. Rekonsiliasi: saldo rekening vs total transaksinya, tampilkan yang selisih saja
-- Expected: kolom account_no, balance, saldo_transaksi, selisih · 0 baris (semua cocok)
-- Petunjuk: saldo_transaksi = SETOR + TRANSFER_MASUK - TARIK - TRANSFER_KELUAR; LEFT JOIN + HAVING


-- R7. Simulasi data rusak: saldo diubah langsung tanpa transaksi. Jalankan UPDATE ini,
--     jalankan R6 lagi (expected 1 baris, selisih 1000000), lalu ROLLBACK.
UPDATE accounts SET balance = balance + 1000000 WHERE account_no = 'SIM-1000006';

ROLLBACK;
