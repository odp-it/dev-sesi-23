# 23 - Oracle Querying & Optimization

Lab ini memakai tabel dan data Tabungan UMKM dari sesi 22. Hasil akhirnya: query laporan dan rekonsiliasi lintas tabel, transfer yang di-commit dan di-rollback dengan bukti dari dua session, bukti before/after index `IDX_TXN_ACCOUNT_AT` dari execution plan, satu query mutasi yang dijalankan dari Java atau Node.js dengan bind variable, dan laporan serta optimasi untuk aplikasi ALP tim yang dinilai dengan rubrik 100 poin.

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

## Struktur Repo

| Folder | Isi |
| --- | --- |
| [`demo-1/`](demo-1/) | Demo 1 · Query Laporan & Validasi |
| [`demo-2/`](demo-2/) | Demo 2 · Transfer dengan Commit & Rollback |
| [`demo-3/`](demo-3/) | Demo 3 · Explain Plan Before/After Index |
| [`demo-4/`](demo-4/) | Demo 4 · Query dari Java atau Node.js |
| [`lab/`](lab/) | Lab · Laporan + Optimasi untuk Aplikasi ALP Tim |

Setiap folder punya `README.md` berisi langkahnya. Kerjakan berurutan: `demo-1` sampai `demo-4`, lalu `lab`.

## Studi Kasus

Tim operasional bank fiktif Tabungan UMKM butuh laporan saldo per cabang, mutasi rekening per bulan, daftar nasabah yang belum aktif bertransaksi, dan arus kas UMKM per kategori untuk dashboard. Setiap transfer harus berhasil berdua (debit dan kredit) atau batal berdua, dan saldo rekening harus selalu cocok dengan total transaksinya. Saat data membesar, query mutasi harus tetap cepat. Aplikasi Java dan Node.js nanti membaca data yang sama.

## Bantuan

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): pesan error dan cara memperbaikinya.
- [CHECKLIST.md](CHECKLIST.md): hasil yang harus terlihat dan kriteria selesai.

## Cleanup

1. (Opsional) `demo-3/03b-hapus-bulk.sql` untuk menghapus data bulk. Data uji `UJI-` di tabel tim boleh dibiarkan.
2. Tutup terminal supaya `ORACLE_PASSWORD` hilang dari memori.
3. `docker stop oracle-alp` kalau sudah selesai.

Schema, data, dan index ini dipakai lagi di sesi 30–33 saat REST API Express membaca dan menulis tabel yang sama, kali ini dengan connection pool dan konfigurasi `.env`.
