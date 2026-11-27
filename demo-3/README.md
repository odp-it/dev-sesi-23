# Demo 3 · Explain Plan Before/After Index

[Persiapan](../README.md) · [Troubleshooting](../TROUBLESHOOTING.md)

Kerjakan 3.0-3.4: baca execution plan, buat index, dan bandingkan sebelum dan sesudah.

## 3.0 Izin membaca statistik eksekusi

`DBMS_XPLAN.DISPLAY_CURSOR` (dipakai di P3 dan P6) membaca view sistem `V$SQL` dan `V$SESSION`. User `ALP_DEV` belum punya izin itu. Di laptop sendiri kamu admin database-nya, jadi berikan izinnya sekali lewat terminal di folder `demo-3`:

```bash
docker cp setup/02-grant-plan-stats.sql oracle-alp:/tmp/02-grant-plan-stats.sql
docker exec -it oracle-alp sqlplus / as sysdba "@/tmp/02-grant-plan-stats.sql"
```

Yang harus terlihat: `Grant succeeded.` empat kali, lalu `Izin statistik plan untuk ALP_DEV selesai.` Docker Desktop kadang menambahkan teks `What's next:` di bawahnya; abaikan saja.

## 3.1 Tambah data bulk

Buka `03-bulk-transactions.sql`, pasang koneksi, tekan **F5**. Tunggu 10-20 detik.

Yang harus terlihat di akhir **Script Output**: `200000 rows inserted.`, `Commit complete.`, `JUMLAH_TRANSAKSI 200127`, `JUMLAH_REKENING 515`. Angka `200127` berlaku bila transfer Demo 2 sudah di-commit; kalau belum, `200125`.

Data bulk masuk ke rekening uji `SIM-2000001` s.d. `SIM-2000500` milik `CIF-SIM-9999` di `KCP-SIM-99`. Rekening Tabungan UMKM asli tidak berubah, jadi mutasi `SIM-1000004` (account_id 4) tetap 4 transaksi di Februari.

## 3.2 Plan dan Buffers sebelum index

Buka `04-explain-plan.sql`, pasang koneksi. Jalankan satu per satu dengan Run Statement:

1. P1: daftar index di `TRANSACTIONS`. Yang harus terlihat: hanya `PK_TRANSACTIONS` dan `UQ_TRANSACTIONS_REF`.
2. P2: `EXPLAIN PLAN ...`, lalu `SELECT ... DBMS_XPLAN.DISPLAY(...)`. Hasil tampil di **Query Result** sebagai teks plan.
3. Coba juga cara GUI: taruh kursor di `SELECT` P3, tekan **F10**, pilih **Explain Plan**. Hasilnya muncul di tab **Explain Plan**, isinya sama dengan P2.
4. P3: jalankan `SELECT /*+ GATHER_PLAN_STATISTICS */ ...` (4 baris hasil), lalu `SELECT ... DISPLAY_CURSOR(...)`. Klik ikon maximize di panel bawah supaya tabel plan terbaca utuh.

Catat ke tabel ini (angka dari kolom baris `Id 0`):

| Kondisi | Operation untuk `TRANSACTIONS` | Cost | Buffers | A-Rows |
| --- | --- | --- | --- | --- |
| Sebelum index | | | | |
| Sesudah index | | | | |

## 3.3 Buat index dan bandingkan

1. P4: `CREATE INDEX idx_txn_account_at ...`. Yang harus terlihat: `Index IDX_TXN_ACCOUNT_AT created.`
2. P5: plan sesudah index (atau **F10** di `SELECT` P6).
3. P6: jalankan query dengan statistik lalu `DISPLAY_CURSOR`.
4. Lengkapi baris "Sesudah index" di tabel.

Yang harus terlihat: operation berubah, cost dan Buffers turun jauh, A-Rows tetap 4. Angka E-Rows (perkiraan optimizer) sama di kedua plan; yang berubah cara membacanya.

## 3.4 Pola yang membuat index tidak terpakai

Jalankan P7 dan P8 (masing-masing `EXPLAIN PLAN` lalu `DISPLAY`). Tulis satu kalimat untuk masing-masing: kenapa plan-nya tidak memakai `IDX_TXN_ACCOUNT_AT`. Lihat slide *Pola yang Bikin Index Tidak Dipakai*.

## 3.5 (Opsional) Hapus data bulk

Kalau ingin data kembali kecil sebelum Demo 4 atau sesi berikutnya: buka `03b-hapus-bulk.sql`, tekan **F5**. Yang harus terlihat: `JUMLAH_TRANSAKSI 127`. Index tetap ada.

## Tantangan tambahan Demo 3 (opsional)

Kerjakan di file baru. Data bulk dan index `IDX_TXN_ACCOUNT_AT` dari langkah 3.1-3.3 sudah ada (untuk nomor 2 index itu wajib ada).

1. Cari satu transaksi dengan `ref_no = 'REF-SIM-000070'`. Lewat `EXPLAIN PLAN` dan `DBMS_XPLAN.DISPLAY`, index mana yang dipakai Oracle, dan kenapa index itu sudah ada tanpa kamu membuatnya?
2. Bandingkan dua plan untuk rekening 4 di Februari 2026: `SELECT COUNT(*)` dan `SELECT ref_no`. Mana yang cukup membaca index saja, dan mana yang masih membuka tabel? Cari baris `TABLE ACCESS` di plan.
