# Demo 2 · Transfer dengan Commit & Rollback

[Persiapan](../README.md) · [Troubleshooting](../TROUBLESHOOTING.md)

Kerjakan 2.0–2.7 berpasangan: transfer dalam satu transaksi, dilihat dari dua session.

Satu laptop, dua tab editor. Setiap tab worksheet SQL Developer for VS Code memakai session database sendiri.

## 2.0 Siapkan dua session

1. Buka `02-transfer.sql`, pasang koneksi `ALP_DEV @ FREEPDB1`. Ini **session A**.
2. Buka `02-cek-session-b.sql`, klik kanan tab-nya → **Split Right** (atau Command Palette → **View: Split Editor Right**), lalu tutup tab `02-cek-session-b.sql` yang tersisa di kiri. Pasang koneksi di editor kanan. Ini **session B**.

Yang harus terlihat: dua editor berdampingan, status bar keduanya `(Dedicated) ALP_DEV @ FREEPDB1`.

## 2.1 Catat saldo awal

Session A: jalankan 2.1. Catat saldo:

| Rekening | Saldo awal |
| --- | --- |
| SIM-1000001 | |
| SIM-1000003 | |

## 2.2 Jalankan transfer tanpa commit

Session A: jalankan 4 perintah 2.2 satu per satu (2 `UPDATE`, 2 `INSERT`). Yang harus terlihat di **Script Output**: `1 row updated.` dua kali, `1 row inserted.` dua kali.

Kalau `UPDATE` pertama menghasilkan `0 rows updated.`, berhenti di sini dan jalankan `ROLLBACK;`: rekening sumber tidak aktif atau saldonya kurang.

## 2.3 Bandingkan dua session

1. Session A: jalankan 2.3. Saldo sudah berubah.
2. Session B: jalankan kedua query (saldo dan `REF-SIM-T%`).

Yang harus terlihat di session B: saldo masih sama dengan saldo awal, dan query transaksi `REF-SIM-T%` menghasilkan 0 baris. Perubahan session A belum terlihat oleh session lain karena belum di-commit.

## 2.4 Commit dan cek lagi

1. Session A: jalankan `COMMIT;`. Yang harus terlihat: `Commit complete.`
2. Session B: jalankan lagi kedua query. Saldo sekarang sama dengan di session A, dan ada 2 transaksi `REF-SIM-T00001` (`TRANSFER_KELUAR`) dan `REF-SIM-T00002` (`TRANSFER_MASUK`).

## 2.5–2.7 Transfer gagal dan rollback

1. Session A: jalankan dua `UPDATE` di 2.5 satu per satu. `UPDATE` pertama (kredit ke `SIM-1000010`) berhasil. `UPDATE` kedua ditolak:

```text
ORA-02290: check constraint (ALP_DEV.CK_ACCOUNTS_BALANCE) violated
```

2. Jalankan query 2.6. Yang harus terlihat: `SIM-1000010` sudah bertambah 50.000.000, padahal debitnya gagal. Data setengah jadi.
3. Jalankan `ROLLBACK;` lalu query terakhir (2.7). Yang harus terlihat: saldo `SIM-1000010` kembali seperti sebelum 2.5.

Kesimpulan yang dicatat: error di satu perintah tidak otomatis membatalkan perintah sebelumnya dalam transaksi yang sama. Aplikasi yang harus memanggil `ROLLBACK` (sesi 31 melakukannya dari Node.js).

## Tantangan tambahan Demo 2 (opsional)

Kerjakan dari satu worksheet, tanpa `COMMIT`; semua dibatalkan di akhir.

1. Transfer 250.000 dari `SIM-1000005` ke `SIM-1000006`. Setelah debit, buat `SAVEPOINT setelah_debit`. Kredit pertama sengaja salah rekening tujuan (`SIM-1000099`: `0 rows updated.`). Batalkan hanya kredit itu dengan `ROLLBACK TO SAVEPOINT`, kredit ke rekening yang benar, tampilkan kedua saldo, lalu `ROLLBACK` semuanya.
2. Ulangi langkah 2.5, lalu sebelum `ROLLBACK` jalankan query rekonsiliasi R6. Rekening mana yang muncul, dan berapa selisihnya? Setelah `ROLLBACK`, R6 kembali 0 baris.
