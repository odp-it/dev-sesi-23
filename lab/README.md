> Buka folder ini untuk bagian ini. Semua path relatif terhadap folder ini. Persiapan, troubleshooting, dan cleanup: [README utama](../README.md).

# Lab · Laporan + Optimasi untuk Aplikasi ALP Tim (±35 menit, boleh lanjut setelah kelas)

**Skenario.** Schema ALP tim dari Lab sesi 22 akan dipakai backend. Tim lead meminta paket database untuk rilis pertama dashboard: satu laporan ringkasan, satu laporan data yang belum punya pasangan, satu query validasi yang bisa dijalankan kapan saja, satu proses bisnis yang aman sebagai transaksi, dan query yang paling sering dipakai aplikasi sudah dibantu index dengan bukti execution plan. Semua dinilai dengan rubrik di bawah.

Satu laptop per tim, schema `ALP_DEV` milik laptop itu. Tim yang schema Lab sesi 22-nya belum jadi, selesaikan dulu minimal 3 tabel dengan relasi FK (template Lab sesi 22).

1. Salin `lab-alp-tim.sql` menjadi `lab-alp-<nama-tim>.sql`. Pakai awalan tabel yang sama dengan Lab sesi 22 (mis. `GRD_`); semua view dan index memakai awalan itu.
2. Bagian 1: bangkitkan data uji sampai tabel transaksi utama minimal 5.000 baris (pola `../demo-3/03-bulk-transactions.sql`: `CONNECT BY` dan `MOD`, penanda `UJI-`, lalu `DBMS_STATS.GATHER_TABLE_STATS`).
3. Bagian 2–4: buat tiga view dengan nama persis ini: `<awalan>_LAP_RINGKASAN` (JOIN minimal 2 tabel tim + `GROUP BY`), `<awalan>_LAP_TANPA_PASANGAN` (`LEFT JOIN` atau `NOT EXISTS`, 2 tabel tim, hasil minimal 1 baris), dan `<awalan>_CEK_VALIDASI` (data sehat = 0 baris). Buktikan validasinya: rusak satu data, hitung lagi, `ROLLBACK`.
4. Bagian 5: tulis satu proses bisnis sebagai transaksi (minimal 2 perintah DML): satu skenario berhasil dengan `COMMIT`, satu skenario gagal yang di-`ROLLBACK`, dengan `SELECT` sebelum dan sesudah.
5. Bagian 6: buat view `<awalan>_QUERY_UTAMA` berisi query yang paling sering dipakai aplikasi, dengan `WHERE` berisi nilai contoh. Catat plan sebelum index, buat index composite berawalan tim, catat plan sesudahnya.
6. Jalankan file Lab dengan **F5** sampai tidak ada error selain penolakan yang disengaja di bagian 5.
7. Buka `cek-lab.sql`, ganti awalan di baris `DEFINE awalan = 'GRD'` (huruf besar, tanpa garis bawah), pasang koneksi, tekan **F5**. Output berupa tabel poin otomatis (maks. 80). Perbaiki file Lab tim lalu jalankan cek lagi.

## Rubrik Lab (100 poin)

| Kriteria | Poin | Dinilai oleh | Indikator keberhasilan |
| --- | --- | --- | --- |
| Laporan ringkasan | 20 | `cek-lab.sql` | `LAP_RINGKASAN` berisi minimal 1 baris (8), membaca minimal 2 tabel tim (6), memakai `GROUP BY` (6) |
| Laporan tanpa pasangan | 10 | `cek-lab.sql` | `LAP_TANPA_PASANGAN` minimal 1 baris (4), 2 tabel tim (3), `LEFT JOIN` atau `NOT EXISTS` (3) |
| Query validasi | 10 | `cek-lab.sql` | `CEK_VALIDASI` membaca tabel tim (5) dan menghasilkan 0 baris pada data sehat (5) |
| Data uji | 10 | `cek-lab.sql` | Tabel tim terbesar minimal 5.000 baris (10), atau minimal 1.000 baris (5) |
| Index buatan tim | 10 | `cek-lab.sql` | Index di tabel tim di luar index PK/`UNIQUE`: composite (10), satu kolom (5) |
| Query utama + plan | 20 | `cek-lab.sql` | `QUERY_UTAMA` memakai `WHERE` dan berisi minimal 1 baris (5); plan memakai index buatan tim lewat range atau unique scan (15) |
| Transaksi | 10 | Instruktur atau tim lain | Proses bisnis minimal 2 DML dengan `COMMIT` (5); skenario gagal di-`ROLLBACK` dan data terbukti kembali (5) |
| Bukti before/after | 5 | Instruktur atau tim lain | Tabel operation dan cost (plus Buffers bila 3.0 sudah dijalankan) sebelum dan sesudah index |
| Bukti validasi | 5 | Instruktur atau tim lain | Data sengaja dirusak, `CEK_VALIDASI` menampilkannya, `ROLLBACK`, kembali 0 baris |
| **Total** | **100** | | |

Kalau waktu kelas mepet, dahulukan kriteria wajib: laporan ringkasan (20), query validasi (10), index buatan tim (10), query utama + plan (20) = 60 poin. Skor kurang dari 60 setelah waktu kelas habis: lanjutkan setelah kelas sampai memenuhi rubrik. Tugas lanjutan tidak dikumpulkan; cek sendiri dengan `cek-lab.sql` dan rubrik di atas.

`cek-lab.sql` membaca katalog, menjalankan `SELECT` pada view tim, dan membuat plan `QUERY_UTAMA`. Baris plan milik skrip dibatalkan lagi (`ROLLBACK TO SAVEPOINT`), jadi data dan transaksi yang belum di-commit tidak berubah.

## Bonus Lab (opsional, maks. +10)

1. (+5) Jalankan query utama tim dari Java atau Node.js: salin `Main.java` atau `mutasi.mjs`, ganti SQL-nya, kirim nilai filter lewat bind variable, password tetap dari environment variable. Jalankan juga dengan nilai berisi `' OR '1'='1` dan catat hasilnya.
2. (+5) Tambah satu view `<awalan>_LAP_PERSENTASE`: porsi tiap kelompok terhadap total (subquery di dalam `ROUND`, seperti Tantangan tambahan Demo 1).
