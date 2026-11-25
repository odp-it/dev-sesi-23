# 23 - Oracle Querying & Optimization

Lab ini memakai tabel dan data Tabungan UMKM dari sesi 22. Hasil akhirnya: query laporan dan rekonsiliasi lintas tabel, transfer yang di-commit dan di-rollback dengan bukti dari dua session, bukti before/after index `IDX_TXN_ACCOUNT_AT` dari execution plan, satu query mutasi yang dijalankan dari Java atau Node.js dengan bind variable, dan laporan serta optimasi untuk aplikasi ALP tim yang dinilai dengan rubrik 100 poin.

## Tujuan

1. Menulis query lintas tabel dengan `INNER JOIN`, `LEFT JOIN`, aggregate, `CASE`, dan `EXISTS` untuk laporan dan validasi data.
2. Menjalankan transfer sebagai satu transaksi dengan `COMMIT` dan `ROLLBACK`, dan membuktikan bahwa session lain belum melihat data yang belum di-commit.
3. Membaca execution plan (`EXPLAIN PLAN`, `DBMS_XPLAN`, Explain Plan di SQL Developer) dan membandingkan cost serta Buffers sebelum dan sesudah index.
4. Menjalankan query Oracle dari Java (JDBC) atau Node.js (node-oracledb Thin) dengan bind variable.

## Estimasi Waktu

Format sesi: **4 Demo + 1 Lab**. Di tiap Demo instruktur memperagakan, lalu peserta mengikuti langkah bernomor dari file *starter* di folder ini. Demo 1 dan 2 inti sesi (query laporan, transaksi): wajib selesai. Demo 3 (explain plan dan index) penting. Demo 4 (query dari Java atau Node.js) penerapan. **Lab** adalah tugas tim yang menerapkan Demo 1–4 ke aplikasi ALP, dinilai dengan rubrik 100 poin dan cek otomatis. Tiap Demo punya **Tantangan tambahan** untuk yang selesai lebih cepat (tidak wajib).

| Bagian | Durasi di kelas (peraga + ikuti) |
| --- | --- |
| Demo 1 · Query laporan & validasi | ±55 menit (20 + 35) |
| Demo 2 · Transfer dengan commit & rollback (berpasangan) | ±35 menit (10 + 25) |
| Demo 3 · Explain plan before/after index | ±45 menit (20 + 25) |
| Demo 4 · Query dari Java atau Node.js | ±25 menit (10 + 15) |
| **Lab** · Laporan + optimasi aplikasi ALP tim (boleh lanjut setelah kelas) | ±35 menit |
| **Total** | **±195 menit** (+ pembuka 10 dan penutup 5 = 210) |

## Environment & Tools

Disiapkan sebelum kelas. Versi dikunci: jangan update tool selama kelas.

| Item | Versi | Cara cek | Harus terlihat |
| --- | --- | --- | --- |
| Container Oracle | Oracle AI Database 26ai Free 23.26.4 (`container-registry.oracle.com/database/free:23.26.4.0-lite`) | `docker ps` | `oracle-alp` dengan status `(healthy)` |
| Data sesi 22 | | Run Statement `SELECT COUNT(*) FROM transactions;` sebagai `ALP_DEV` | `125` (atau `127` kalau Demo 2 sudah pernah dikerjakan) |
| VS Code + Oracle SQL Developer for VS Code | 26.3.1 | Panel SQL Developer | Koneksi `ALP_DEV @ FREEPDB1` |
| Pilihan Java: JDK | Temurin/OpenJDK 25 (sama dengan sesi 13) | `java -version` | `openjdk version "25...` |
| Pilihan Java: driver | `ojdbc17-23.26.4.0.0.jar` (Maven Central) | Didownload di langkah 4.1 | File ±8,4 MB di `java/lib/` |
| Pilihan Node.js | Node.js 26 LTS (24 LTS juga jalan) + `oracledb` 26.0.0 | `node --version` | `v26...` atau `v24...` |

Versi dicek 22 Nov 2026 (Maven Central, npm registry, Marketplace VS Code). Hanya satu dari Java atau Node.js yang wajib; kerjakan yang lain kalau waktu masih ada.

Kalau tabel sesi 22 belum lengkap atau rusak: buka `demo-1/catchup/00-catchup-sesi-22.sql`, pasang koneksi, tekan **F5**. Hasil akhirnya `BRANCHES 3`, `CUSTOMERS 12`, `ACCOUNTS 15`, `TRANSACTIONS 125`, `TOTAL_SALDO 218000000`.

Tiap file `.sql` baru harus dipasangi koneksi sendiri (kalau lupa: `Error: No session associated with the current worksheet`). Kalau VS Code menanyakan `Do you trust the authors of the files in this folder?`, pilih **Trust Folder & Continue**; ekstensi SQL Developer butuh ±20 detik untuk aktif setelah VS Code dibuka. Container `Exited (255)` setelah laptop dimatikan: `docker start oracle-alp`, tunggu `(healthy)`.

Cara menjalankan SQL sama dengan sesi 22: pasang koneksi lewat status bar, **Run Statement** `Ctrl+Enter` (Windows/Linux) atau `⌘Enter` (macOS) untuk satu perintah, **Run Script** `F5` untuk satu file, **Explain Plan** `F10`. Auto Commit mati.

## Struktur Repo

| Folder | Isi |
| --- | --- |
| [`demo-1/`](demo-1/) | Demo 1 · Query Laporan & Validasi |
| [`demo-2/`](demo-2/) | Demo 2 · Transfer dengan Commit & Rollback |
| [`demo-3/`](demo-3/) | Demo 3 · Explain Plan Before/After Index |
| [`demo-4/`](demo-4/) | Demo 4 · Query dari Java atau Node.js |
| [`lab/`](lab/) | Lab · Laporan + Optimasi untuk Aplikasi ALP Tim |

Setiap folder punya `README.md` berisi langkahnya. Kerjakan berurutan: `demo-1` sampai `demo-4`, lalu `lab`.

## Demo dan Lab

Demo 1, 3, dan 4 dikerjakan **individu**. Demo 2 dikerjakan **berpasangan**: satu orang mengetik, satu orang mencatat dan mencocokkan expected result, lalu bertukar peran di 2.5. Lab dikerjakan **per tim ALP**.

### Target

| Bagian | Hasil |
| --- | --- |
| Demo 1 | `demo-1/01-report-queries.sql` berisi R1b–R6 yang hasilnya sesuai expected, plus bukti R7 (selisih muncul lalu hilang setelah rollback) |
| Demo 2 | Catatan saldo `SIM-1000001` dan `SIM-1000003` dari session A dan B sebelum dan sesudah `COMMIT`; transfer gagal yang di-rollback |
| Demo 3 | Tabel catatan before/after: operation, cost, Buffers |
| Demo 4 | Output terminal mutasi `SIM-1000004` Februari 2026 dari Java atau Node.js |
| Lab | `lab-alp-<nama-tim>.sql` dengan skor otomatis dari `lab/cek-lab.sql` |

### Studi Kasus

Tim operasional bank fiktif Tabungan UMKM butuh laporan saldo per cabang, mutasi rekening per bulan, daftar nasabah yang belum aktif bertransaksi, dan arus kas UMKM per kategori untuk dashboard. Setiap transfer harus berhasil berdua (debit dan kredit) atau batal berdua, dan saldo rekening harus selalu cocok dengan total transaksinya. Saat data membesar, query mutasi harus tetap cepat. Aplikasi Java dan Node.js nanti membaca data yang sama.

### Kriteria Selesai

- [ ] R1b–R6 sesuai kolom dan jumlah baris expected; R7 menunjukkan selisih lalu bersih lagi setelah `ROLLBACK`
- [ ] Session B tidak melihat transfer sebelum `COMMIT`, dan melihatnya sesudah `COMMIT`
- [ ] Transfer gagal di 2.5 dibatalkan dengan `ROLLBACK`, saldo `SIM-1000010` kembali
- [ ] Tabel before/after index terisi (operation, cost, Buffers)
- [ ] Mutasi `SIM-1000004` Februari 2026 tampil dari Java atau Node.js: 4 transaksi
- [ ] Lab: file Lab tim jalan dan `lab/cek-lab.sql` menampilkan skor otomatis (target minimal 48 dari 80, setara 60%)

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
| 3.2–3.3 | Sebelum: full scan pada `TRANSACTIONS`, Buffers ribuan. Sesudah: `INDEX RANGE SCAN` pada `IDX_TXN_ACCOUNT_AT`, Buffers satu digit. A-Rows 4 di keduanya |
| 4.2 | 4 transaksi, masuk 4.800.000,00, keluar 300.000,00 |
| Lab | `lab/cek-lab.sql` menampilkan 6 baris kriteria dan subtotal otomatis maks. 80 |

Cost dan Buffers bisa sedikit berbeda di laptop lain (ukuran blok, statistik). Yang harus sama: jenis operation, A-Rows, dan selisih yang jauh antara sebelum dan sesudah.

## Troubleshooting

| Masalah / Error | Penyebab | Solusi |
| --- | --- | --- |
| `Error: No session associated with the current worksheet`, atau tombol Run belum aktif | File `.sql` belum dipasangi koneksi, atau folder belum di-Trust | **Attach Connection** di tiap file; **Trust Folder & Continue** pada dialog Restricted Mode |
| Setelah `Read-Host -MaskInput` di Windows PowerShell 5.1 password terlihat di layar | `-MaskInput` hanya ada di PowerShell 7; di 5.1 tidak error | Cek `$PSVersionTable.PSVersion`; di 5.1 pakai blok `-AsSecureString`. Password yang sudah terlihat: ganti password `ALP_DEV` (ulang 1.4 sesi 21) |
| Angka R1–R6 beda dengan expected | Data sesi 22 tidak lengkap atau sudah berisi data bulk | Jalankan `demo-1/catchup/00-catchup-sesi-22.sql`, lalu ulangi dari Demo 1 |
| Session B langsung melihat perubahan sebelum `COMMIT` | Kedua editor memakai tab/dokumen yang sama, atau `COMMIT` sudah terjalankan | Pastikan B dijalankan dari file `demo-2/02-cek-session-b.sql`, bukan dari `demo-2/02-transfer.sql` |
| Run Statement di session B terus berputar | Session B menjalankan `UPDATE` pada baris yang sedang dikunci session A | Jalankan `COMMIT` atau `ROLLBACK` di session A; session B lanjut sendiri |
| `ORA-00001: unique constraint (ALP_DEV.UQ_TRANSACTIONS_REF) violated` di 2.2 | Transfer 2.2 sudah pernah di-commit (ref `REF-SIM-T00001` sudah ada) | `ROLLBACK;` lalu jalankan catchup, atau ganti ref menjadi `REF-SIM-T00003` dan `REF-SIM-T00004` |
| `ORA-00942: table or view "SYS"."V_$SQL" does not exist` di P3 | Langkah 3.0 belum dijalankan | Jalankan 3.0, lalu ulangi P3 |
| `ORA-00955: name is already used by an existing object` di P4 | Index sudah dibuat sebelumnya | Lanjut saja; untuk mengulang "sebelum index": `DROP INDEX idx_txn_account_at;` |
| `ORA-00001 ... UQ_BRANCHES_CODE` saat 3.1 | Data bulk sudah pernah dimasukkan | Jalankan `demo-3/03b-hapus-bulk.sql`, lalu 3.1 lagi |
| `Set dulu environment variable ORACLE_PASSWORD (lihat README).` | 4.0 belum dijalankan di terminal ini | Ulangi 4.0 |
| `ORA-01017: invalid credential or not authorized; logon denied` | Password salah | Ulangi 4.0 dengan password `ALP_DEV` yang benar |
| `Error: Could not find or load main class Main.java` | JDK lama (mis. Java 8) yang terpakai; Java 8 tidak bisa menjalankan file `.java` langsung | Pakai JDK 25 dari sesi 13; cek `java -version` |
| `java.sql.SQLException: No suitable driver found for jdbc:oracle:thin:@//localhost:1521/FREEPDB1` | `-cp lib/ojdbc17-...jar` lupa ditulis, atau jar belum ada di `lib/` | Ulangi langkah 2, jalankan dengan `-cp` persis seperti contoh |
| `Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'oracledb' imported from ...` | `npm install` belum dijalankan di folder `node` | `cd node` lalu `npm install` |
| Error koneksi (`NJS-...` di Node.js, `IO Error` / `ORA-125xx` di Java) | Container Oracle mati | `docker start oracle-alp`, tunggu `(healthy)` |
| `lab/cek-lab.sql` menampilkan `(0 tabel tim)` | Awalan di `DEFINE awalan` tidak sama dengan awalan tabel, atau DDL tim belum dijalankan | Samakan awalan (huruf besar, tanpa garis bawah), jalankan DDL tim dulu |
| `view belum ada/error` padahal view sudah dibuat | Nama view tidak persis sesuai ketentuan, atau view jadi tidak valid setelah tabel dibuat ulang | Cek nama (`<awalan>_LAP_RINGKASAN`, dan seterusnya), jalankan lagi file Lab tim |
| Kriteria 6 `tanpa index tim` | Filter di `QUERY_UTAMA` tidak sesuai kolom pertama index, kolom dibungkus fungsi, data uji terlalu sedikit, atau statistik belum diperbarui | Lihat plan di 6c, samakan urutan kolom index dengan filter, jalankan `DBMS_STATS` |

## Cleanup

1. (Opsional) `demo-3/03b-hapus-bulk.sql` untuk menghapus data bulk. Data uji `UJI-` di tabel tim boleh dibiarkan.
2. Tutup terminal supaya `ORACLE_PASSWORD` hilang dari memori.
3. `docker stop oracle-alp` setelah kelas.

Schema, data, dan index ini dipakai lagi di sesi 30–33 saat REST API Express membaca dan menulis tabel yang sama, kali ini dengan connection pool dan konfigurasi `.env`.
