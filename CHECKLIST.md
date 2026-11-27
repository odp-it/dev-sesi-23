# Checklist

[Kembali ke README](README.md)

## Kriteria Selesai

- [ ] R1b-R6 sesuai kolom dan jumlah baris expected; R7 menunjukkan selisih lalu bersih lagi setelah `ROLLBACK`
- [ ] Session B tidak melihat transfer sebelum `COMMIT`, dan melihatnya sesudah `COMMIT`
- [ ] Transfer gagal di 2.5 dibatalkan dengan `ROLLBACK`, saldo `SIM-1000010` kembali
- [ ] Tabel before/after index terisi (operation, cost, Buffers)
- [ ] Mutasi `SIM-1000004` Februari 2026 tampil dari Java atau Node.js: 4 transaksi
- [ ] Lab: `db/04` sampai `db/07` ada di repo kelompok, `00-run-all.sql` jalan dua kali tanpa error, dan `lab/cek-lab.sql` sesi 23 menampilkan skor otomatis (target minimal 48 dari 80, setara 60%)
- [ ] Lab: `db/06-transaksi.sql` punya skenario `COMMIT` dan skenario `ROLLBACK`
- [ ] Lab: README repo kelompok berisi peta fitur, laporan, 3 pertanyaan bisnis, dan bukti cek (tanpa `TODO`)

## Verifikasi & Expected Result

| Cek | Expected result |
| --- | --- |
| R1 | 3 baris; `KCP-SIM-03` 3 nasabah (INNER JOIN membuang nasabah tanpa rekening) |
| 1.2 | Jumlah baris R1b 3, R2 3, R3 2, R4 12, R5 0, R6 0 |
| 1.3 | R6 setelah `UPDATE`: 1 baris, `SELISIH` 1000000; setelah `ROLLBACK`: 0 baris |
| 2.3 | Session A melihat saldo baru, session B saldo lama dan 0 transaksi `REF-SIM-T%` |
| 2.4 | Session B melihat saldo baru dan 2 transaksi `REF-SIM-T%`; total saldo semua rekening tetap 218.000.000 |
| 2.5 | `ORA-02290 ... CK_ACCOUNTS_BALANCE`; setelah `ROLLBACK` saldo `SIM-1000010` kembali |
| 3.1 | `JUMLAH_TRANSAKSI 200127`, `JUMLAH_REKENING 515` |
| 3.2-3.3 | Sebelum: full scan pada `TRANSACTIONS`, Buffers ribuan. Sesudah: `INDEX RANGE SCAN` pada `IDX_TXN_ACCOUNT_AT`, Buffers satu digit. A-Rows 4 di keduanya |
| 4.2 | 4 transaksi, masuk 4.800.000,00, keluar 300.000,00 |
| Lab | `lab/cek-lab.sql` menampilkan 6 baris kriteria dan subtotal otomatis maks. 80; `00-run-all.sql` dua kali berturut-turut tanpa error; plan `QUERY_UTAMA` berubah dari `TABLE ACCESS FULL` ke `INDEX RANGE SCAN` pada index kelompok |

Cost dan Buffers bisa sedikit berbeda di laptop lain (ukuran blok, statistik). Yang harus sama: jenis operation, A-Rows, dan selisih yang jauh antara sebelum dan sesudah.
