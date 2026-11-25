-- Sesi 23 · Lab: cek otomatis Laporan + Optimasi ALP Tim (80 poin otomatis; 20 poin dinilai manual)
-- Cara pakai:
--   1. Ganti awalan di baris DEFINE di bawah (huruf besar, tanpa garis bawah), mis. GRD untuk tabel GRD_*.
--   2. Pasang koneksi ALP_DEV @ FREEPDB1, tekan Run Script (F5).
--   3. Baca tabel poin di Script Output. Perbaiki file Lab tim, jalankan lagi, lalu cek lagi.
-- Skrip ini membaca katalog, menjalankan SELECT pada view tim, dan membuat plan query utama.
-- Baris plan milik skrip dibatalkan lagi dengan ROLLBACK TO SAVEPOINT: data dan transaksi tim tidak diubah.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
DEFINE awalan = 'GRD'

DECLARE
  v_awalan   VARCHAR2(30)  := UPPER('&awalan');
  v_pola     VARCHAR2(40)  := UPPER('&awalan') || '\_%';
  n_tabel    PLS_INTEGER;
  n_baris    NUMBER;
  n_maks     NUMBER := 0;
  n_ref      PLS_INTEGER;
  n_idx      PLS_INTEGER := 0;
  n_kolom    PLS_INTEGER := 0;
  n_pakai    PLS_INTEGER := 0;
  v_sql      VARCHAR2(32767);
  v_idx_plan VARCHAR2(200);
  v_hasil    VARCHAR2(60);
  p          PLS_INTEGER;
  p_idx      PLS_INTEGER := 0;
  v_total    PLS_INTEGER := 0;

  PROCEDURE baris(k VARCHAR2, hasil VARCHAR2, poin PLS_INTEGER, maks PLS_INTEGER) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD(k, 32) || RPAD(NVL(hasil, ' '), 30) || LPAD(poin, 3) || ' / ' || LPAD(maks, 2));
  END;

  -- jumlah baris view; -1 = view belum ada atau gagal dijalankan
  FUNCTION isi_view(nama VARCHAR2) RETURN NUMBER IS
    n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO n FROM user_views WHERE view_name = v_awalan || '_' || nama;
    IF n = 0 THEN RETURN -1; END IF;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || v_awalan || '_' || nama || '"' INTO n;
    RETURN n;
  EXCEPTION
    WHEN OTHERS THEN RETURN -1;
  END;

  -- jumlah tabel tim yang dibaca view (termasuk lewat view lain)
  FUNCTION tabel_dibaca(nama VARCHAR2) RETURN PLS_INTEGER IS
    n PLS_INTEGER;
  BEGIN
    SELECT COUNT(DISTINCT referenced_name) INTO n
      FROM (SELECT referenced_name, referenced_type
              FROM user_dependencies
             START WITH name = v_awalan || '_' || nama AND type = 'VIEW'
           CONNECT BY NOCYCLE PRIOR referenced_name = name AND PRIOR referenced_type = type)
     WHERE referenced_type = 'TABLE' AND referenced_name LIKE v_pola ESCAPE '\';
    RETURN n;
  END;

  -- teks view tanpa komentar, huruf besar
  FUNCTION teks_view(nama VARCHAR2) RETURN VARCHAR2 IS
    t VARCHAR2(32767);
  BEGIN
    SELECT text_vc INTO t FROM user_views WHERE view_name = v_awalan || '_' || nama;
    t := REGEXP_REPLACE(t, '--[^' || CHR(10) || ']*', ' ');
    t := REGEXP_REPLACE(t, '/\*([^*]|\*+[^*/])*\*+/', ' ');
    RETURN UPPER(t);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
  END;

  FUNCTION ket(n NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN n < 0 THEN 'view belum ada/error' ELSE n || ' baris' END;
  END;
BEGIN
  IF NOT REGEXP_LIKE(v_awalan, '^[A-Z][A-Z0-9]{1,3}$') THEN
    DBMS_OUTPUT.PUT_LINE('Awalan harus 2-4 huruf/angka tanpa garis bawah. Perbaiki baris DEFINE awalan.');
    RETURN;
  END IF;

  SELECT COUNT(*) INTO n_tabel FROM user_tables WHERE table_name LIKE v_pola ESCAPE '\';

  DBMS_OUTPUT.PUT_LINE('Cek Lab Sesi 23 - awalan ' || v_awalan || '_ (' || n_tabel || ' tabel tim)');
  DBMS_OUTPUT.PUT_LINE(RPAD('Kriteria', 32) || RPAD('Hasil', 30) || 'Poin');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));

  -- 1. Laporan ringkasan (20): jalan dan berisi 8, 2 tabel tim 6, GROUP BY 6
  n_baris := isi_view('LAP_RINGKASAN');
  n_ref := tabel_dibaca('LAP_RINGKASAN');
  p := 0;
  v_hasil := ket(n_baris);
  IF n_baris >= 0 AND n_ref >= 1 THEN
    IF n_baris >= 1 THEN p := p + 8; END IF;
    IF n_ref >= 2 THEN p := p + 6; END IF;
    IF REGEXP_LIKE(teks_view('LAP_RINGKASAN'), 'GROUP[[:space:]]+BY') THEN
      p := p + 6;
      v_hasil := v_hasil || ', ' || n_ref || ' tabel, GROUP BY';
    ELSE
      v_hasil := v_hasil || ', ' || n_ref || ' tabel';
    END IF;
  END IF;
  v_total := v_total + p;
  baris('1. Laporan ringkasan', v_hasil, p, 20);

  -- 2. Laporan tanpa pasangan (10): minimal 1 baris 4, 2 tabel tim 3, LEFT JOIN / NOT EXISTS 3
  n_baris := isi_view('LAP_TANPA_PASANGAN');
  n_ref := tabel_dibaca('LAP_TANPA_PASANGAN');
  p := 0;
  v_hasil := ket(n_baris);
  IF n_baris >= 0 AND n_ref >= 1 THEN
    IF n_baris >= 1 THEN p := p + 4; END IF;
    IF n_ref >= 2 THEN p := p + 3; END IF;
    IF REGEXP_LIKE(teks_view('LAP_TANPA_PASANGAN'),
                   'LEFT[[:space:]]+(OUTER[[:space:]]+)?JOIN|NOT[[:space:]]+EXISTS') THEN
      p := p + 3;
    END IF;
    v_hasil := v_hasil || ', ' || n_ref || ' tabel';
  END IF;
  v_total := v_total + p;
  baris('2. Laporan tanpa pasangan', v_hasil, p, 10);

  -- 3. Query validasi (10): membaca tabel tim 5, hasil 0 baris pada data sehat 5
  n_baris := isi_view('CEK_VALIDASI');
  n_ref := tabel_dibaca('CEK_VALIDASI');
  p := 0;
  v_hasil := ket(n_baris);
  IF n_baris >= 0 THEN
    v_hasil := v_hasil || ', ' || n_ref || ' tabel';
    IF n_ref >= 1 THEN
      p := 5;
      IF n_baris = 0 THEN p := 10; END IF;
    END IF;
  END IF;
  v_total := v_total + p;
  baris('3. Query validasi (0 baris)', v_hasil, p, 10);

  -- 4. Data uji (10): tabel tim terbesar >= 5.000 baris 10, >= 1.000 baris 5
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE v_pola ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || t.table_name || '"' INTO n_baris;
    n_maks := GREATEST(n_maks, n_baris);
  END LOOP;
  p := CASE WHEN n_maks >= 5000 THEN 10 WHEN n_maks >= 1000 THEN 5 ELSE 0 END;
  v_total := v_total + p;
  baris('4. Data uji (min. 5.000 baris)', 'terbesar ' || n_maks || ' baris', p, 10);

  -- 5. Index buatan tim, bukan index milik PK/UNIQUE (10): composite 10, satu kolom 5
  FOR i IN (SELECT ui.index_name,
                   (SELECT COUNT(*) FROM user_ind_columns ic WHERE ic.index_name = ui.index_name) AS kolom
              FROM user_indexes ui
             WHERE ui.table_name LIKE v_pola ESCAPE '\'
               AND ui.index_type <> 'LOB'
               AND NOT EXISTS (SELECT 1 FROM user_constraints c WHERE c.index_name = ui.index_name)) LOOP
    n_idx := n_idx + 1;
    n_kolom := GREATEST(n_kolom, i.kolom);
  END LOOP;
  p_idx := CASE WHEN n_kolom >= 2 THEN 10 WHEN n_idx >= 1 THEN 5 ELSE 0 END;
  v_total := v_total + p_idx;
  baris('5. Index buatan tim (composite)', n_idx || ' index, maks ' || n_kolom || ' kolom', p_idx, 10);

  -- 6. Query utama dan plan (20): view ber-WHERE dan berisi 5, plan memakai index tim 15
  n_baris := isi_view('QUERY_UTAMA');
  n_ref := tabel_dibaca('QUERY_UTAMA');
  p := 0;
  v_hasil := ket(n_baris);
  IF n_baris >= 1 AND n_ref >= 1 AND REGEXP_LIKE(teks_view('QUERY_UTAMA'), '(^|[^A-Z_])WHERE([^A-Z_]|$)') THEN
    p := 5;
    SAVEPOINT cek_lab_23;
    DELETE FROM plan_table WHERE statement_id = 'CEKLAB23';
    v_sql := 'EXPLAIN PLAN SET STATEMENT_ID = ''CEKLAB23'' FOR SELECT * FROM "' || v_awalan || '_QUERY_UTAMA"';
    EXECUTE IMMEDIATE v_sql;
    EXECUTE IMMEDIATE
      'SELECT COUNT(*), MIN(pt.object_name) FROM plan_table pt
        WHERE pt.statement_id = ''CEKLAB23''
          AND pt.operation = ''INDEX''
          AND (pt.options LIKE ''RANGE SCAN%'' OR pt.options LIKE ''UNIQUE SCAN%'')
          AND EXISTS (SELECT 1 FROM user_indexes ui
                       WHERE ui.index_name = pt.object_name
                         AND ui.table_name LIKE :pola ESCAPE ''\''
                         AND NOT EXISTS (SELECT 1 FROM user_constraints c
                                          WHERE c.index_name = ui.index_name))'
      INTO n_pakai, v_idx_plan USING v_pola;
    ROLLBACK TO SAVEPOINT cek_lab_23;
    IF n_pakai >= 1 THEN
      p := 20;
      v_hasil := v_hasil || ', pakai index tim';
    ELSE
      v_hasil := v_hasil || ', tanpa index tim';
    END IF;
  END IF;
  v_total := v_total + p;
  baris('6. Query utama + plan', v_hasil, p, 20);
  IF v_idx_plan IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('   plan: INDEX scan pada ' || v_idx_plan);
  END IF;

  DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
  baris('Subtotal otomatis', ' ', v_total, 80);
  DBMS_OUTPUT.PUT_LINE('Dinilai manual (20): transaksi 10, bukti before/after 5, bukti validasi 5.');
END;
/
