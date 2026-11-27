# Troubleshooting

[Kembali ke README](README.md)

| Masalah / Error | Penyebab | Solusi |
| --- | --- | --- |
| `Error: No session associated with the current worksheet`, atau tombol Run belum aktif | File `.sql` belum dipasangi koneksi, atau folder belum di-Trust | **Attach Connection** di tiap file; **Trust Folder & Continue** pada dialog Restricted Mode |
| Setelah `Read-Host -MaskInput` di Windows PowerShell 5.1 password terlihat di layar | `-MaskInput` hanya ada di PowerShell 7; di 5.1 tidak error | Cek `$PSVersionTable.PSVersion`; di 5.1 pakai blok `-AsSecureString`. Password yang sudah terlihat: ganti password `ALP_DEV` (ulang 1.4 sesi 21) |
| Angka R1-R6 beda dengan expected | Data sesi 22 tidak lengkap atau sudah berisi data bulk | Jalankan `demo-1/catchup/00-catchup-sesi-22.sql`, lalu ulangi dari Demo 1 |
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
| `lab/cek-lab.sql` menampilkan `(0 tabel tim)` | Awalan di `DEFINE awalan` tidak sama dengan awalan tabel, atau DDL kelompok belum dijalankan | Samakan awalan (huruf besar, tanpa garis bawah), jalankan `db/00-run-all.sql` dulu |
| `view belum ada/error` padahal view sudah dibuat | Nama view tidak persis sesuai ketentuan, atau view jadi tidak valid setelah tabel dibuat ulang | Cek nama (`<awalan>_LAP_RINGKASAN`, dan seterusnya), jalankan lagi file Lab tim |
| Kriteria 6 `tanpa index tim` | Filter di `QUERY_UTAMA` tidak sesuai kolom pertama index, kolom dibungkus fungsi, data uji terlalu sedikit atau terlalu terkonsentrasi (mis. 6.000 baris di 10 entitas tetap full scan), atau statistik belum diperbarui | Sebar data uji ke ±500 entitas, samakan urutan kolom index dengan filter, lihat plan di `db/07-index.sql`, jalankan `DBMS_STATS` |
