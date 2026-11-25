-- Sesi 23 · Lab: laporan + optimasi untuk aplikasi ALP tim (rubrik 100 poin; cek otomatis: cek-lab.sql)
-- Salin file ini menjadi lab-alp-<nama-tim>.sql. Pakai tabel ALP tim dari Lab sesi 22 (awalan tim,
-- mis. GRD_). Jalankan di schema ALP_DEV. Semua nama view dan index memakai awalan yang sama.
-- Semua contoh di bawah masih berupa komentar: ganti <...> dengan nama tabel dan kolom tim, lalu hapus "-- ".
-- Data simulasi saja.

-- 1. Data uji: tabel transaksi utama tim minimal 5.000 baris
--    Dibangkitkan dengan rumus (CONNECT BY, MOD) seperti ../demo-3/03-bulk-transactions.sql. Beri penanda data uji
--    (mis. kode berawalan 'UJI-') supaya bisa dihapus lagi, dan hapus dulu data uji lama supaya file
--    aman dijalankan ulang. Tabel induk juga perlu cukup banyak baris, mis. 200 pelanggan uji.
--    Semua constraint tetap berlaku untuk data uji.
-- DELETE FROM <awalan>_<tabel_transaksi> WHERE <kolom_kode> LIKE 'UJI-%';
-- INSERT INTO <awalan>_<tabel_transaksi> (<kolom>, ...)
-- SELECT 'UJI-' || LPAD(g.n, 6, '0'),
--        <rumus FK dengan MOD(g.n, <jumlah baris induk>)>,
--        TIMESTAMP '2026-01-01 08:00:00' + NUMTODSINTERVAL(MOD(g.n * 7919, 89 * 24 * 60), 'MINUTE'),
--        ...
-- FROM (SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 20000) g;
-- COMMIT;
-- BEGIN DBMS_STATS.GATHER_TABLE_STATS(USER, '<AWALAN>_<TABEL_TRANSAKSI>'); END;
-- /

-- 2. Laporan ringkasan untuk dashboard: JOIN minimal 2 tabel tim + GROUP BY
-- CREATE OR REPLACE VIEW <awalan>_lap_ringkasan AS
-- SELECT ...
-- FROM <awalan>_<tabel_1> a
-- JOIN <awalan>_<tabel_2> b ON b.<fk> = a.<pk>
-- GROUP BY ...;
-- SELECT * FROM <awalan>_lap_ringkasan FETCH FIRST 10 ROWS ONLY;

-- 3. Laporan data tanpa pasangan (mis. pelanggan tanpa transaksi): LEFT JOIN atau NOT EXISTS, 2 tabel tim.
--    Hasilnya harus minimal 1 baris: siapkan satu data induk yang memang belum punya pasangan.
-- CREATE OR REPLACE VIEW <awalan>_lap_tanpa_pasangan AS
-- SELECT ...;
-- SELECT * FROM <awalan>_lap_tanpa_pasangan;

-- 4. Query validasi / rekonsiliasi: tampilkan HANYA data yang melanggar aturan bisnis tim.
--    Data sehat = 0 baris.
-- CREATE OR REPLACE VIEW <awalan>_cek_validasi AS
-- SELECT ...;
-- SELECT COUNT(*) AS baris_bermasalah FROM <awalan>_cek_validasi;

--    Bukti validasi (dinilai manual): rusak satu data, hitung lagi (minimal 1), ROLLBACK, hitung lagi (0).
-- UPDATE <awalan>_<tabel> SET <kolom> = <nilai salah> WHERE <kunci> = <nilai>;
-- SELECT COUNT(*) AS baris_bermasalah FROM <awalan>_cek_validasi;
-- ROLLBACK;
-- SELECT COUNT(*) AS baris_bermasalah FROM <awalan>_cek_validasi;

-- 5. Transaksi (dinilai manual): satu proses bisnis aplikasi tim berisi minimal 2 perintah DML.
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

-- 6. Optimasi query yang paling sering dipakai aplikasi tim.
--    Isi view dengan query itu apa adanya, termasuk WHERE berisi nilai contoh.
-- CREATE OR REPLACE VIEW <awalan>_query_utama AS
-- SELECT ...
-- FROM <awalan>_<tabel_transaksi> t
-- WHERE t.<kolom_filter> = <nilai contoh>
--   AND t.<kolom_waktu> >= TIMESTAMP '2026-02-01 00:00:00'
--   AND t.<kolom_waktu> <  TIMESTAMP '2026-03-01 00:00:00';

--    6a. Plan SEBELUM index
-- DROP INDEX IF EXISTS <awalan>_idx_<nama>;
-- EXPLAIN PLAN SET STATEMENT_ID = 'tim-sebelum' FOR SELECT * FROM <awalan>_query_utama;
-- SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'tim-sebelum', 'TYPICAL'));

--    6b. Index composite: kolom filter "=" dulu, kolom rentang sesudahnya
-- CREATE INDEX <awalan>_idx_<nama> ON <awalan>_<tabel_transaksi> (<kolom_filter>, <kolom_waktu>);

--    6c. Plan SESUDAH index
-- EXPLAIN PLAN SET STATEMENT_ID = 'tim-sesudah' FOR SELECT * FROM <awalan>_query_utama;
-- SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'tim-sesudah', 'TYPICAL'));

--    6d. Bukti before/after (dinilai manual): isi tabel ini dari hasil 6a dan 6c.
--        Buffers hanya bila langkah 3.0 sudah dijalankan (GATHER_PLAN_STATISTICS + DISPLAY_CURSOR).
-- | Kondisi       | Operation untuk tabel utama | Cost | Buffers |
-- | Sebelum index |                             |      |         |
-- | Sesudah index |                             |      |         |
