-- Sesi 23 · TEMPLATE LAMA (satu file). Lab sekarang memakai db/04-test-data.sql s.d. db/07-index.sql di repo kelompok
-- (template odp-it/alp-db-template); file ini hanya rujukan pola. Cek otomatis tetap cek-lab.sql sesi 23.
-- Pakai tabel ALP kelompok dari Lab sesi 22 (awalan kelompok, mis. GRD_). Semua nama view dan index memakai
-- awalan yang sama. Semua contoh di bawah berupa komentar: ganti <...> dengan nama tabel dan kolom kelompok.
-- Data simulasi saja.

-- 1. Test data: tabel transaksi utama kelompok minimal 5.000 baris (disarankan 50.000)
--    Di-generate dengan rumus (CONNECT BY, MOD) seperti ../demo-3/03-bulk-transactions.sql. Beri penanda test data
--    (mis. kode berawalan 'UJI-') supaya bisa dihapus lagi, dan hapus dulu test data lama supaya file
--    aman dijalankan ulang. Sebar ke ±500 parent test (akun/pembeli/kurir untuk test): dengan sedikit parent, optimizer
--    tetap memilih full scan dan index tidak terpakai.
--    Semua constraint tetap berlaku untuk test data.
-- DELETE FROM <awalan>_<tabel_transaksi> WHERE <kolom_kode> LIKE 'UJI-%';
-- INSERT INTO <awalan>_<tabel_transaksi> (<kolom>, ...)
-- SELECT 'UJI-' || LPAD(g.n, 6, '0'),
--        <rumus FK dengan MOD(g.n, 500)>,
--        TIMESTAMP '2026-01-01 08:00:00' + NUMTODSINTERVAL(MOD(g.n * 7919, 89 * 24 * 60), 'MINUTE'),
--        ...
-- FROM (SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 50000) g;
-- COMMIT;
-- BEGIN DBMS_STATS.GATHER_TABLE_STATS(USER, '<AWALAN>_<TABEL_TRANSAKSI>'); END;
-- /

-- 2. Laporan ringkasan untuk dashboard: JOIN minimal 2 tabel kelompok + GROUP BY
-- CREATE OR REPLACE VIEW <awalan>_lap_ringkasan AS
-- SELECT ...
-- FROM <awalan>_<tabel_1> a
-- JOIN <awalan>_<tabel_2> b ON b.<fk> = a.<pk>
-- GROUP BY ...;
-- SELECT * FROM <awalan>_lap_ringkasan FETCH FIRST 10 ROWS ONLY;

-- 3. Laporan data tanpa pasangan (mis. pelanggan tanpa transaksi): LEFT JOIN atau NOT EXISTS, 2 tabel kelompok.
--    Hasilnya harus minimal 1 baris: siapkan satu data parent yang memang belum punya pasangan.
-- CREATE OR REPLACE VIEW <awalan>_lap_tanpa_pasangan AS
-- SELECT ...;
-- SELECT * FROM <awalan>_lap_tanpa_pasangan;

-- 4. Query validasi / rekonsiliasi: tampilkan HANYA data yang melanggar aturan bisnis kelompok.
--    Data sehat = 0 baris.
-- CREATE OR REPLACE VIEW <awalan>_cek_validasi AS
-- SELECT ...;
-- SELECT COUNT(*) AS baris_bermasalah FROM <awalan>_cek_validasi;

--    Bukti validasi (dinilai manual): rusak satu data, hitung lagi (minimal 1), ROLLBACK, hitung lagi (0).
-- UPDATE <awalan>_<tabel> SET <kolom> = <nilai salah> WHERE <kunci> = <nilai>;
-- SELECT COUNT(*) AS baris_bermasalah FROM <awalan>_cek_validasi;
-- ROLLBACK;
-- SELECT COUNT(*) AS baris_bermasalah FROM <awalan>_cek_validasi;

-- 5. Transaksi (dinilai manual): satu proses bisnis aplikasi kelompok berisi minimal 2 perintah DML.
--    Pilih data yang kondisinya bisa diulang, atau kembalikan di awal bagian ini.
--    5a. Berhasil: tampilkan data sebelum, jalankan DML, COMMIT, tampilkan sesudah.
-- SELECT ... ;
-- UPDATE ... ;
-- INSERT INTO ... ;
-- COMMIT;
-- SELECT ... ;
--    5b. Gagal: perintah kedua sengaja ditolak constraint (catat kode ORA di komentar), cek data setengah
--        jadi, ROLLBACK, buktikan data kembali.
-- UPDATE ... ;
-- INSERT INTO ... ;   -- expected ORA-.....
-- SELECT ... ;
-- ROLLBACK;
-- SELECT ... ;

-- 6. Optimasi query yang paling sering dipakai aplikasi kelompok.
--    Isi view dengan query itu apa adanya, termasuk WHERE berisi nilai contoh.
-- CREATE OR REPLACE VIEW <awalan>_query_utama AS
-- SELECT ...
-- FROM <awalan>_<tabel_transaksi> t
-- WHERE t.<kolom_filter> = <nilai contoh>
--   AND t.<kolom_waktu> >= TIMESTAMP '2026-02-01 00:00:00'
--   AND t.<kolom_waktu> <  TIMESTAMP '2026-03-01 00:00:00';

--    6a. Plan SEBELUM index
-- DROP INDEX IF EXISTS <awalan>_idx_<nama>;
-- EXPLAIN PLAN SET STATEMENT_ID = 'kelompok-sebelum' FOR SELECT * FROM <awalan>_query_utama;
-- SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'kelompok-sebelum', 'TYPICAL'));

--    6b. Index composite: kolom filter "=" dulu, kolom rentang sesudahnya
-- CREATE INDEX <awalan>_idx_<nama> ON <awalan>_<tabel_transaksi> (<kolom_filter>, <kolom_waktu>);

--    6c. Plan SESUDAH index
-- EXPLAIN PLAN SET STATEMENT_ID = 'kelompok-sesudah' FOR SELECT * FROM <awalan>_query_utama;
-- SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'kelompok-sesudah', 'TYPICAL'));

--    6d. Bukti before/after (dinilai manual): isi tabel ini dari hasil 6a dan 6c.
--        Buffers hanya bila langkah 3.0 sudah dijalankan (GATHER_PLAN_STATISTICS + DISPLAY_CURSOR).
-- | Kondisi       | Operation untuk tabel utama | Cost | Buffers |
-- | Sebelum index |                             |      |         |
-- | Sesudah index |                             |      |         |
