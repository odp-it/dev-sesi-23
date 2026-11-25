// Sesi 23 · Mutasi rekening dari Java (JDBC + PreparedStatement)
// Jalankan dari folder java/ (lihat README Demo 4):
//   macOS/Linux : java -cp lib/ojdbc17-23.26.4.0.0.jar Main.java SIM-1000004 2026-02
//   Windows     : java -cp lib\ojdbc17-23.26.4.0.0.jar Main.java SIM-1000004 2026-02
// Password dibaca dari environment variable ORACLE_PASSWORD (tidak ditulis di file).
// User bawaan ALP_DEV; bisa diganti lewat environment variable ORACLE_USER.
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

public class Main {
    static final Locale ID = Locale.forLanguageTag("id-ID");
    static final DateTimeFormatter WAKTU = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    static final String URL = "jdbc:oracle:thin:@//localhost:1521/FREEPDB1";
    static final String USER = System.getenv().getOrDefault("ORACLE_USER", "ALP_DEV");

    static final String SQL = """
        SELECT t.txn_at, t.txn_type, t.category, t.amount, t.ref_no
        FROM transactions t
        JOIN accounts a ON a.account_id = t.account_id
        WHERE a.account_no = ?
          AND t.txn_at >= ?
          AND t.txn_at < ?
        ORDER BY t.txn_at
        """;

    public static void main(String[] args) throws Exception {
        String accountNo = args.length > 0 ? args[0] : "SIM-1000004";
        YearMonth bulan = YearMonth.parse(args.length > 1 ? args[1] : "2026-02");
        String password = System.getenv("ORACLE_PASSWORD");
        if (password == null || password.isBlank()) {
            System.err.println("Set dulu environment variable ORACLE_PASSWORD (lihat README).");
            System.exit(1);
        }

        try (Connection conn = DriverManager.getConnection(URL, USER, password);
             PreparedStatement ps = conn.prepareStatement(SQL)) {
            // Nilai dari user selalu lewat bind (?), tidak disambung ke string SQL
            ps.setString(1, accountNo);
            ps.setTimestamp(2, Timestamp.valueOf(bulan.atDay(1).atStartOfDay()));
            ps.setTimestamp(3, Timestamp.valueOf(bulan.plusMonths(1).atDay(1).atStartOfDay()));

            System.out.printf("Mutasi %s bulan %s%n", accountNo, bulan);
            int baris = 0;
            BigDecimal masuk = BigDecimal.ZERO, keluar = BigDecimal.ZERO;
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String jenis = rs.getString("txn_type");
                    BigDecimal amount = rs.getBigDecimal("amount");
                    System.out.printf(ID, "%s  %-15s %-12s %,15.2f  %s%n",
                        rs.getTimestamp("txn_at").toLocalDateTime().format(WAKTU), jenis, rs.getString("category"),
                        amount, rs.getString("ref_no"));
                    if (jenis.equals("SETOR") || jenis.equals("TRANSFER_MASUK")) masuk = masuk.add(amount);
                    else keluar = keluar.add(amount);
                    baris++;
                }
            }
            System.out.printf(ID, "%d transaksi · masuk %,.2f · keluar %,.2f%n", baris, masuk, keluar);
        }
    }
}
