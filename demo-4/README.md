# Demo 4 · Query dari Java atau Node.js

[Persiapan](../README.md) · [Troubleshooting](../TROUBLESHOOTING.md)

Kerjakan 4.0-4.2: jalankan query dari Java atau Node.js dengan bind variable.

Pilih satu jalur. Keduanya menjalankan query mutasi yang sama dengan bind variable dan mencetak hasil yang sama. Koneksi langsung satu kali, tanpa connection pool dan tanpa file `.env` (dibahas di sesi 30).

## 4.0 Simpan password di environment variable

Password tidak ditulis di file kode. Buka terminal di folder `demo-4`, ketik perintah sesuai OS, lalu ketik password `ALP_DEV` (tidak tampil di layar) dan Enter.

macOS / Linux (zsh):

```bash
read -s "ORACLE_PASSWORD?Password ALP_DEV: " && export ORACLE_PASSWORD; echo
```

Linux (bash):

```bash
read -s -p "Password ALP_DEV: " ORACLE_PASSWORD && export ORACLE_PASSWORD; echo
```

**Windows: cek dulu versi PowerShell dengan `$PSVersionTable.PSVersion`. Kalau `5.1`, pakai blok PowerShell 5.1 di bawah. Memakai `-MaskInput` di 5.1 tidak error, tetapi password terlihat jelas di layar.**

Windows (PowerShell 7):

```powershell
$env:ORACLE_PASSWORD = Read-Host -MaskInput "Password ALP_DEV"
```

Windows PowerShell 5.1 (bawaan Windows, `-MaskInput` tidak ada; input disembunyikan lewat `-AsSecureString`):

```powershell
$s = Read-Host -AsSecureString "Password ALP_DEV"
$env:ORACLE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
```

Variabel ini hanya berlaku di terminal itu. Buka terminal baru = ulangi 4.0.

## 4.1-4.2 · Jalur Java

1. Masuk ke folder `java` dan cek JDK:

```bash
cd java
java -version
```

Yang harus terlihat: `openjdk version "25...`.

2. Download driver JDBC (sekali saja). macOS/Linux:

```bash
curl -L -o lib/ojdbc17-23.26.4.0.0.jar --create-dirs https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc17/23.26.4.0.0/ojdbc17-23.26.4.0.0.jar
```

Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force lib | Out-Null
curl.exe -L -o lib\ojdbc17-23.26.4.0.0.jar https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc17/23.26.4.0.0/ojdbc17-23.26.4.0.0.jar
```

3. Buka `Main.java`, baca bagian `SQL` dan `ps.setString(1, ...)`: nilai dari user masuk lewat `?`, tidak disambung ke string SQL.
4. Jalankan (Java 25 bisa menjalankan satu file `.java` langsung, tanpa compile terpisah):

macOS/Linux:

```bash
java -cp lib/ojdbc17-23.26.4.0.0.jar Main.java SIM-1000004 2026-02
```

Windows:

```powershell
java -cp lib\ojdbc17-23.26.4.0.0.jar Main.java SIM-1000004 2026-02
```

Yang harus terlihat:

```text
Mutasi SIM-1000004 bulan 2026-02
2026-02-07 12:20  TARIK           BAHAN_BAKU        300.000,00  REF-SIM-000055
2026-02-09 14:50  SETOR           PENJUALAN       1.450.000,00  REF-SIM-000060
2026-02-16 13:05  TRANSFER_MASUK  TRANSFER        1.500.000,00  REF-SIM-000068
2026-02-18 15:30  SETOR           PENJUALAN       1.850.000,00  REF-SIM-000070
4 transaksi · masuk 4.800.000,00 · keluar 300.000,00
```

5. Ganti argumen, mis. `SIM-1000001 2026-03`, dan jalankan lagi.

## 4.1-4.2 · Jalur Node.js

1. Masuk ke folder `node` dan install dependency (sekali saja):

```bash
cd node
npm install
```

Yang harus terlihat: `added 1 package`. Peringatan `npm warn install-scripts ... oracledb@26.0.0` boleh diabaikan: script itu hanya untuk Thick mode, lab ini memakai Thin mode.

2. Buka `mutasi.mjs`, baca bagian `sql` dan `conn.execute(sql, { accountNo, dari, sampai })`: nilai dari user masuk lewat `:accountNo`, tidak disambung ke string SQL.
3. Jalankan:

```bash
node mutasi.mjs SIM-1000004 2026-02
```

Yang harus terlihat: sama dengan jalur Java, dengan baris pertama `Mutasi SIM-1000004 bulan 2026-02 (oracledb 26.0.0, mode Thin)`.

4. Ganti argumen, mis. `SIM-1000001 2026-03`, dan jalankan lagi.

## Tantangan tambahan Demo 4 (opsional)

Pilih Java atau Node.js (atau keduanya). Jangan mengubah file asli: salin dulu (`Main.java` menjadi `MutasiJenis.java`, nama kelas ikut diganti; `mutasi.mjs` menjadi `mutasi-jenis.mjs`).

1. Tambahkan argumen ke-3 opsional: jenis transaksi (`SETOR`, `TARIK`, ...). Kalau diisi, hanya jenis itu yang tampil; kalau kosong, semua jenis. Nilai jenis harus lewat bind variable. Coba `SIM-1000004 2026-02 SETOR` dan `SIM-1000004 2026-02 TARIK`.
2. Test ketahanan bind variable: jalankan program dengan nomor rekening berisi tanda kutip dan `OR`: `"SIM-1000004' OR '1'='1"`. Berapa transaksi yang tampil, dan kenapa itu jawaban yang benar? Bayangkan kalau nilainya disambung ke string SQL.
