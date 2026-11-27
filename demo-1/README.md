# Demo 1 · Query Laporan & Validasi

[Persiapan](../README.md) · [Troubleshooting](../TROUBLESHOOTING.md)

Kerjakan 1.1-1.3: query laporan dengan `JOIN`, aggregate, `EXISTS`, dan query validasi.

Buka `01-report-queries.sql`, pasang koneksi `ALP_DEV @ FREEPDB1`. R1 sudah dijawab sebagai contoh.

## 1.1 Jalankan R1 dan baca hasilnya

Jalankan R1 dengan Run Statement. Yang harus terlihat: 3 baris, `KCP-SIM-03` punya `JUMLAH_NASABAH` 3, padahal cabang itu punya 4 nasabah.

## 1.2 Kerjakan R1b-R6

Tulis query di bawah tiap soal, jalankan, cocokkan kolom dan jumlah baris dengan keterangan `Expected`. Sintaks: lihat slide *INNER JOIN*, *LEFT JOIN untuk Data Tanpa Pasangan*, *JOIN Tiga Tabel*, *Subquery dan EXISTS*, *Rekonsiliasi Saldo*.

Titik rawan:
- `COUNT(*)` menghitung baris hasil JOIN, termasuk baris kosong dari `LEFT JOIN`. Untuk "tidak punya pasangan", hitung kolom dari tabel kanan, mis. `COUNT(t.txn_id)`.
- Filter tabel kanan di `WHERE` mengubah `LEFT JOIN` menjadi seperti `INNER JOIN`.
- R5 dan R6 yang benar menghasilkan **0 baris**. Query validasi yang "kosong" artinya datanya bersih.

## 1.3 Simulasi data rusak

1. Jalankan `UPDATE` di bawah R7. Yang harus terlihat: `1 row updated.`
2. Jalankan lagi query R6. Yang harus terlihat: 1 baris `SIM-1000006` dengan `SELISIH` `1000000`.
3. Jalankan `ROLLBACK;`, lalu R6 sekali lagi: kembali 0 baris.

## Tantangan tambahan Demo 1 (opsional)

Tulis di `01-report-queries.sql` sebagai R8 dan R9, jalankan di data sesi 22 (sebelum data bulk).

1. R8: nasabah yang punya rekening `AKTIF` tetapi tidak punya satu pun transaksi di Februari 2026, dengan kode cabangnya dan jumlah rekening aktifnya. Petunjuk: `NOT EXISTS`, dan transaksi dicari lewat rekening milik nasabah itu.
2. R9: total saldo tiap cabang dan persentasenya terhadap total saldo semua cabang (satu desimal). Petunjuk: subquery `(SELECT SUM(balance) FROM accounts)` di dalam `ROUND(...)`.
