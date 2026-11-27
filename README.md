# 23 - Oracle Querying & Optimization

Demo memakai tabel dan data Tabungan UMKM dari sesi 22 (fitur keuangan digital untuk nasabah UMKM sebuah bank fiktif). Hasil Demo: query laporan dan rekonsiliasi lintas tabel, transfer yang di-commit dan di-rollback dengan bukti dari dua session, bukti before/after index `IDX_TXN_ACCOUNT_AT` dari execution plan, dan satu query mutasi dari Java atau Node.js dengan bind variable. Lab adalah **Tahap 3 project ALP**: tiap kelompok mengerjakan hal yang sama untuk database kelompoknya sendiri di repo kelompok (`db/04`–`db/07`, README bagian laporan dan bukti cek), lalu mempresentasikannya di akhir sesi 24.

## Environment & Tools

Siapkan sebelum mulai. Versi dikunci: jangan update tool di tengah pengerjaan.

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

## Posisi Sesi di Project ALP

Sesi 21–24 membentuk satu project: setiap kelompok (3–4 orang, laptop pribadi) menghasilkan database ALP yang bisa dibangun ulang, terdokumentasi, dan dipresentasikan. Demo selalu memakai kasus Tabungan UMKM; Lab adalah langkah yang sama untuk tema kelompok (Perbankan, E-commerce, atau Logistik) di repo kelompok.

| Tahap | Sesi | Hasil di repo kelompok |
| --- | --- | --- |
| 1 | 21 | `docs/erd.drawio.png`, `docs/kamus-data.md`, `docs/review.md` |
| 2 | 22 | `db/01-ddl.sql`, `db/02-seed.sql`, `db/03-test-invalid.sql`, `db/00-run-all.sql` |
| **3** | **23 (sesi ini)** | `db/04-data-uji.sql`, `db/05-laporan.sql`, `db/06-transaksi.sql`, `db/07-index.sql`, README bagian peta fitur, laporan, pertanyaan bisnis, bukti cek |
| Presentasi | 24, 16.00–17.00 | 5 menit presentasi + 3 menit tanya jawab per kelompok, tanpa slide, README sebagai alur, demo langsung |

Urutan presentasi diumumkan di akhir sesi ini.

## Jembatan ke Tema Kelompok

Setiap konsep Demo punya padanan di tema kelompok. Nama view dan index di tabel ini adalah contoh dari tiga kelompok fiktif (KasUMKM, PasarUMKM, KirimUMKM); kelompok memakai awalan dan nama kolomnya sendiri.

| Konsep di Demo (Tabungan UMKM) | Perbankan (`KAS_`) | E-commerce (`MKT_`) | Logistik (`KRM_`) |
| --- | --- | --- | --- |
| Laporan `GROUP BY` (R1–R4, Demo 1) → `<awalan>_LAP_RINGKASAN` | Arus kas per UMKM per bulan | Penjualan per produk per bulan | Kiriman per gudang per bulan per status |
| Data tanpa pasangan (R5, `LEFT JOIN`) → `<awalan>_LAP_TANPA_PASANGAN` | Akun yang belum pernah dipakai | Produk yang belum pernah dipesan | Kurir yang belum pernah ditugaskan |
| Validasi dan rekonsiliasi (R6, R7) → `<awalan>_CEK_VALIDASI` | Saldo vs total transaksi | Pesanan berbayar vs pembayaran, total vs isi pesanan | Status vs riwayat terakhir, berat vs kapasitas kurir |
| Transaksi `COMMIT`/`ROLLBACK` (Demo 2) → `db/06-transaksi.sql` | Catat pengeluaran + kurangi saldo | Checkout + kurangi stok | Serah ke kurir + catat riwayat |
| Query utama + index (Demo 3) → `<awalan>_QUERY_UTAMA`, `db/07-index.sql` | `KAS_IDX_TXN_ACCOUNT_AT (account_id, txn_at)` | `MKT_IDX_ORDERS_BUYER_AT (buyer_id, ordered_at)` | `KRM_IDX_SHIPMENTS_COURIER_AT (courier_id, created_at)` |

Pola index sama di ketiganya: kolom filter `=` dulu, kolom rentang waktu sesudahnya.

## Struktur Repo

| Folder | Isi |
| --- | --- |
| [`demo-1/`](demo-1/) | Demo 1 · Query Laporan & Validasi |
| [`demo-2/`](demo-2/) | Demo 2 · Transfer dengan Commit & Rollback |
| [`demo-3/`](demo-3/) | Demo 3 · Explain Plan Before/After Index |
| [`demo-4/`](demo-4/) | Demo 4 · Query dari Java atau Node.js |
| [`lab/`](lab/) | Lab · Tahap 3 Project: Laporan, Transaksi, dan Index |

Setiap folder punya `README.md` berisi langkahnya. Kerjakan berurutan: `demo-1` sampai `demo-4`, lalu `lab`.

## Studi Kasus

Tabungan UMKM adalah fitur keuangan digital untuk nasabah UMKM sebuah bank fiktif. Tim operasional bank fiktif ini butuh laporan saldo per cabang, mutasi rekening per bulan, daftar nasabah yang belum aktif bertransaksi, dan arus kas UMKM per kategori untuk dashboard. Setiap transfer harus berhasil berdua (debit dan kredit) atau batal berdua, dan saldo rekening harus selalu cocok dengan total transaksinya. Saat data membesar, query mutasi harus tetap cepat. Aplikasi Java dan Node.js nanti membaca data yang sama.

## Bantuan

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): pesan error dan cara memperbaikinya.
- [CHECKLIST.md](CHECKLIST.md): hasil yang harus terlihat dan kriteria selesai.

## Cleanup

1. (Opsional) `demo-3/03b-hapus-bulk.sql` untuk menghapus data bulk. Data uji `UJI` di repo kelompok dibiarkan: laporan dashboard memfilter data `SIM`.
2. Tutup terminal supaya `ORACLE_PASSWORD` hilang dari memori.
3. `docker stop oracle-alp` kalau sudah selesai.

Schema, data, dan index ini dipakai lagi di sesi 30–33 saat REST API Express membaca dan menulis tabel yang sama, kali ini dengan connection pool dan konfigurasi `.env`.
