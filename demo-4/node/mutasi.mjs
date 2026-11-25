// Sesi 23 · Mutasi rekening dari Node.js (node-oracledb Thin + bind variable)
// Jalankan dari folder node/ (lihat README Demo 4):
//   node mutasi.mjs SIM-1000004 2026-02
// Password dibaca dari environment variable ORACLE_PASSWORD (tidak ditulis di file).
// User bawaan ALP_DEV; bisa diganti lewat environment variable ORACLE_USER.
// Satu koneksi langsung, tanpa connection pool (pool dan .env dibahas di sesi 30).
import oracledb from 'oracledb';

const accountNo = process.argv[2] ?? 'SIM-1000004';
const bulan = process.argv[3] ?? '2026-02';
const password = process.env.ORACLE_PASSWORD;
if (!password) {
  console.error('Set dulu environment variable ORACLE_PASSWORD (lihat README).');
  process.exit(1);
}

const [tahun, bln] = bulan.split('-').map(Number);
const dari = new Date(tahun, bln - 1, 1);
const sampai = new Date(tahun, bln, 1);

const sql = `
  SELECT t.txn_at, t.txn_type, t.category, t.amount, t.ref_no
  FROM transactions t
  JOIN accounts a ON a.account_id = t.account_id
  WHERE a.account_no = :accountNo
    AND t.txn_at >= :dari
    AND t.txn_at < :sampai
  ORDER BY t.txn_at`;

const conn = await oracledb.getConnection({
  user: process.env.ORACLE_USER ?? 'ALP_DEV',
  password,
  connectString: 'localhost:1521/FREEPDB1',
});

try {
  // Nilai dari user selalu lewat bind (:nama), tidak disambung ke string SQL
  const result = await conn.execute(sql, { accountNo, dari, sampai }, {
    outFormat: oracledb.OUT_FORMAT_OBJECT,
  });

  const rupiah = new Intl.NumberFormat('id-ID', { minimumFractionDigits: 2 });
  const waktu = (d) => d.toLocaleString('sv-SE').slice(0, 16);
  console.log(`Mutasi ${accountNo} bulan ${bulan} (oracledb ${oracledb.versionString}, mode ${oracledb.thin ? 'Thin' : 'Thick'})`);
  let masuk = 0;
  let keluar = 0;
  for (const r of result.rows) {
    console.log(`${waktu(r.TXN_AT)}  ${r.TXN_TYPE.padEnd(15)} ${r.CATEGORY.padEnd(12)} ${rupiah.format(r.AMOUNT).padStart(15)}  ${r.REF_NO}`);
    if (r.TXN_TYPE === 'SETOR' || r.TXN_TYPE === 'TRANSFER_MASUK') masuk += r.AMOUNT;
    else keluar += r.AMOUNT;
  }
  console.log(`${result.rows.length} transaksi · masuk ${rupiah.format(masuk)} · keluar ${rupiah.format(keluar)}`);
} finally {
  await conn.close();
}
