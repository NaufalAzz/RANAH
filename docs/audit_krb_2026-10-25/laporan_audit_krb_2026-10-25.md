# Audit dan inventaris KRB seluruh gunung database RANAH

Tanggal akses sumber: 2026-10-25. Database dibaca secara read-only dari konfigurasi Laravel; tidak ada data database yang diubah.

## Ringkasan

- Record gunung database: **69**.
- Gunung dengan geometri BIG yang lolos verifikasi dan masuk ke aset peta: **27** (151 fitur geometri).
- Gunung dengan sebagian zona saja pada data BIG yang ditemukan: **0**.
- Record tanpa geometri terverifikasi untuk integrasi peta: **42**.
- Geometri KRB kandidat ditemukan untuk **68** gunung; **1** gunung tidak ditemukan pada layer (Hobal).
- Seluruh 68 grup kandidat yang ditemukan memiliki kelas I, II, dan III pada atribut layer; fitur kandidat tidak otomatis dianggap cocok untuk gunung database.
- Semua 395 geometri yang diambil pada subset record database lulus pemeriksaan struktur koordinat, rentang WGS84, ring tertutup, dan luas tidak nol.
- Tahun sumber KRB yang tercatat pada `thterbit` berada pada rentang **1996-2016**.

### Prioritas Sumatera Barat

| Gunung | Hasil | Zona | Tahun | Catatan lokasi |
|---|---|---|---|---|
| Marapi | TERVERIFIKASI_SUMBER_WILAYAH_DAN_BUKTI_PUBLIK | I/II/III tersedia | 2006 | Marker database sekitar 1 km di luar poligon; sumber puncak resmi berada di dalam. |
| Talang | TERVERIFIKASI_NAMA_METADATA_DAN_WILAYAH | I/II/III tersedia | 2007 | Marker database sekitar 22.69 km di luar poligon; perlu rekonsiliasi. |
| Tandikat | TERVERIFIKASI_NAMA_METADATA_DAN_WILAYAH | I/II/III tersedia | 2007 | Marker database sekitar 10.73 km di luar poligon; perlu rekonsiliasi. |

### Kelompok status verifikasi

| Status | Jumlah | Makna |
|---|---:|---|
| `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | 17 | Nama/kategori ditemukan, tetapi koordinat DB kosong. |
| `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | 24 | Nama/kategori ditemukan, tetapi koordinat record tersimpan di luar geometri; dikecualikan dari aset verified. |
| `TERVERIFIKASI_NAMA_DAN_LOKASI` | 24 | Nama/alias, kelas, geometri, dan koordinat berada dalam geometri sumber. |
| `TERVERIFIKASI_NAMA_METADATA_DAN_WILAYAH` | 2 | Talang dan Tandikat; nama, kelas, metadata, dan wilayah konsisten. Marker DB berjarak dari poligon sehingga butuh rekonsiliasi. |
| `TERVERIFIKASI_SUMBER_WILAYAH_DAN_BUKTI_PUBLIK` | 1 | Marapi; identitas/wilayah diverifikasi lewat layer dan rujukan resmi Badan Geologi. Marker DB punya selisih yang dicatat. |
| `TIDAK_DITEMUKAN` | 1 | Tidak ada fitur layer yang cocok. |

## Layer dan metode

- Layer: [BIG Satu Peta KRB Gunung Api Area (MapServer 11)](https://kspservices.big.go.id/satupeta/rest/services/PUBLIK/SUMBER_DAYA_ALAM_DAN_LINGKUNGAN/MapServer/11).
- Service Item ID: `86a1e71887224f45aa041e45f0bea5f0`; SRID 4326; geometri `esriGeometryPolygon`; format query GeoJSON tersedia.
- Atribut yang diperiksa: `namobj`, `indga` (1/2/3), `thterbit`, `metadata`, `remark`, `srs_id`, `objectid`.
- Query atribut layer menemukan 596 fitur; query subset berdasarkan nama yang beririsan dengan daftar DB mengambil 395 geometri, bukan semua poligon administrasi atau layer lain.
- Aset peta dibuat dari 151 fitur untuk 27 gunung yang melewati kriteria; request BIG menggunakan `outSR=4326` dan `maxAllowableOffset=0.0002` (generalisasi kira-kira 22 m di ekuator) untuk ukuran tampilan. Ini bukan data survei dan tidak boleh digunakan untuk keputusan evakuasi.
- Tiap fitur aset memuat source URL, tanggal akses, tahun sumber, `objectid`, `indga`, status verifikasi, koordinat reference, dan alasan pencocokan.
- Koordinat gunung tidak diubah. 24 record dengan geometri bernama sama ditahan karena koordinat DB berada di luar geometri. 17 record tidak punya koordinat; Hobal tidak punya kandidat pada layer.

## Bukti dan batasan sumber

- Metadata BIG secara eksplisit menyebut layer sebagai polygon, SRID 4326, `indga` renderer KRB I-III, dan atribut `thterbit`; data source layer yang diperiksa merupakan publikasi geospasial BIG.
- [Siaran Badan Geologi tentang Marapi (29 Maret 2024)](https://geologi.esdm.go.id/media-center/update-aktivitas-terkini-g-marapi-sumatera-barat) menyebut koordinat puncak dan melampirkan peta KRB Marapi. Koordinat puncak rujukan berada di geometri Marapi BIG; koordinat marker yang tersimpan berbeda sekitar 1 km.
- [Katalog Perpustakaan Badan Geologi - pencarian KRB](https://geologi.esdm.go.id/perpustakaan/?search=Search&subject=%22Kawasan+rawan+bencana%22) memuat entri "Verifikasi Peta Kawasan Rawan Bencana Gunungapi Talang, Sumatera Barat". Layer BIG mempunyai fitur TALANG tahun 2007 dan TANDIKAT tahun 2007; marker DB masing-masing sekitar 22.69 km dan 10.73 km di luar poligon, jadi rekonsiliasi koordinat dibutuhkan.
- [Katalog Perpustakaan Badan Geologi tentang Hobal](https://geologi.esdm.go.id/perpustakaan/?search=Search&subject=%22Gunungapi+Hobal%22) memuat laporan inspeksi Hobal dan Ili Werung dari 1974-1981 dan keterangan Hobal bawah laut yang dikaitkan dengan daerah bahaya/waspada gunung sekitar. Katalog tersebut tidak menyediakan vektor KRB terpisah yang dapat diperiksa, sehingga Hobal tetap tanpa overlay.
- Tahun data tertua dan terbaru pada subset yang ditarik adalah 1996 dan 2016. Tidak ada bukti pada layer ini bahwa geometri telah diperbarui setelah tahun `thterbit`; jangan menyebutnya kondisi terbaru.
- Layanan layer BIG menyediakan geometri, tetapi bukan sumber status aktivitas gunung. Status MAGMA tetap terpisah.
- GeoJSON simulasi asli `ranah_mobile/assets/geojson/ranah_krb_simulasi.geojson` dipertahankan utuh; data resmi disimpan pada aset terpisah.

## Hasil untuk semua 69 record

| ID | Gunung | Koordinat DB | Nama objek BIG | Tahun | Zona | Fitur | Status | Catatan |
|---:|---|---|---|---|---|---:|---|---|
| 1 | Marapi | terverifikasi | MARAPI | 2006 | 1/2/3 | 6 | `TERVERIFIKASI_SUMBER_WILAYAH_DAN_BUKTI_PUBLIK` | Marker DB sekitar 1 km di luar poligon; koordinat puncak pada sumber Badan Geologi berada di dalam geometri. |
| 2 | Anak Krakatau | belum tervalidasi | ANAK KRAKATAU | 2007 | 1/2/3 | 5 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 3 | Merapi | terverifikasi | MERAPI | 2010 | 1/2/3 | 4 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 4 | Semeru | terverifikasi | SEMERU | 1996 | 1/2/3 | 5 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 5 | Anak Ranakah | terverifikasi | ANAK RANAKAH | 2010 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 6 | Awu | terverifikasi | AWU | 2016 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 7 | Banda Api | belum tervalidasi | BANDA API | 2008 | 1/2/3 | 5 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 8 | Bromo | terverifikasi | BROMO | 2015 | 1/2/3 | 5 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 9 | Bur Ni Telong | terverifikasi | BURNI TELONG | 2008 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 10 | Dempo | belum tervalidasi | DEMPO | 2009 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 11 | Dukono | terverifikasi | DUKONO | 2008 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 12 | Gamalama | terverifikasi | GAMALAMA | 1996 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 13 | Ibu | terverifikasi | IBU | 2008 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 14 | Ili Lewotolok | belum tervalidasi | LEWOTOLO | 2010 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 15 | Iya | belum tervalidasi | IYA | 2010 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 16 | Karangetang | belum tervalidasi | KARANGETANG | 2011 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 17 | Kerinci | terverifikasi | KERINCI | 2014 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 18 | Lewotobi Laki | belum tervalidasi | LEWOTOBI LAKI LAKI | 2009 | 1/2/3 | 3 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 19 | Lokon | terverifikasi | LOKON | 2015 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 20 | Raung | terverifikasi | RAUNG | 2007 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 21 | Rinjani | terverifikasi | RINJANI | 2008 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 22 | Sangeangapi | terverifikasi | SANGEANG API | 2008, 2016 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 23 | Sinabung | terverifikasi | SINABUNG | 2015 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 24 | Slamet | terverifikasi | SLAMET | 2006 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 25 | Soputan | terverifikasi | SOPUTAN | 2006 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 26 | Sorikmarapi | belum tervalidasi | SORIK MARAPI | 2008 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 27 | Tambora | terverifikasi | TAMBORA | 2008 | 1/2/3 | 5 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 28 | Agung | terverifikasi | AGUNG | 2015 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 29 | Ambang | terverifikasi | AMBANG | 2007 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 30 | Arjuno Welirang | belum tervalidasi | ARJUNO WELIRANG | 2009 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 31 | Batur | terverifikasi | BATUR | 2015 | 1/2/3 | 5 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 32 | Batutara | belum tervalidasi | BATUTARA | 2012 | 1/2/3 | 4 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 33 | Ciremai | belum tervalidasi | CIREMAI | 2006 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 34 | Colo | terverifikasi | COLO | 2004 | 1/2/3 | 5 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 35 | Dieng | terverifikasi | DIENG | 2011 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 36 | Ebulobo | terverifikasi | EBULOBO | 2007 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 37 | Egon | terverifikasi | EGON | 2005 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 38 | Galunggung | terverifikasi | GALUNGGUNG | 2016 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 39 | Gamkonora | terverifikasi | GAMKONORA | 2006 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 40 | Gede | terverifikasi | GEDE | 2008 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 41 | Guntur | terverifikasi | GUNTUR | 2015 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 42 | Hobal | belum tervalidasi | - | - | - | 0 | `TIDAK_DITEMUKAN` | Katalog Badan Geologi memuat laporan Hobal lama, tetapi tidak menyediakan vektor KRB terpisah yang dapat divalidasi. |
| 43 | Ijen | terverifikasi | IJEN | 2006 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 44 | Ile Werung | belum tervalidasi | ILE WERUNG | 2010 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 45 | Ili Boleng | terverifikasi | ILE BOLENG | 2010 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 46 | Inielika | terverifikasi | INIELIKA | 2009 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 47 | Inierie | terverifikasi | INIERIE | 2009 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 48 | Kaba | belum tervalidasi | KABA | 2008 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 49 | Kelimutu | terverifikasi | KELIMUTU | 2008 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 50 | Kelud | terverifikasi | KELUD | 2014 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 51 | Kie Besi | belum tervalidasi | KIE BESI | 2008 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 52 | Lamongan | terverifikasi | LAMONGAN | 2015 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 53 | Lereboleng | terverifikasi | LEREBOLENG | 2010 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 54 | Lewotobi Perempuan | terverifikasi | LEWOTOBI PEREMPUAN | 2009 | 1/2/3 | 3 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 55 | Mahawu | belum tervalidasi | MAHAWU | 2006, 2007 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 56 | Papandayan | terverifikasi | PAPANDAYAN | 2010 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 57 | Peut Sague | belum tervalidasi | PEUT SAGUE | 2007 | 1/2/3 | 6 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 58 | Rokatenda | terverifikasi | ROKATENDA | 2013 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 59 | Ruang | belum tervalidasi | RUANG | 2007 | 1/2/3 | 5 | `DITEMUKAN_BELUM_VERIFIKASI_LOKASI` | Koordinat kosong; perlukan validasi lokasi independen. |
| 60 | Salak | terverifikasi | SALAK | 2006 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 61 | Seulawah Agam | terverifikasi | SEULAWAH AGAM | 2007 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 62 | Sirung | terverifikasi | SIRUNG | 2010 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 63 | Sumbing | terverifikasi | SUMBING | 2006, 2010 | 1/2/3 | 12 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 64 | Sundoro | terverifikasi | SUNDORO | 2007 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 65 | Talang | terverifikasi | TALANG | 2007 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_METADATA_DAN_WILAYAH` | Marker DB sekitar 22.69 km di luar poligon; perlu rekonsiliasi koordinat. |
| 66 | Tandikat | terverifikasi | TANDIKAT | 2007 | 1/2/3 | 6 | `TERVERIFIKASI_NAMA_METADATA_DAN_WILAYAH` | Koordinat marker DB berada sekitar 10.73 km di luar poligon; rekonsiliasi koordinat diperlukan. |
| 67 | Tangkoko | terverifikasi | TANGKOKO | 2010 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |
| 68 | Tangkuban Parahu | terverifikasi | TANGKUBAN PARAHU | 2005 | 1/2/3 | 5 | `TERVERIFIKASI_NAMA_DAN_LOKASI` | - |
| 69 | Wurlali | terverifikasi | WURLALI | 2010 | 1/2/3 | 6 | `DITEMUKAN_KONFLIK_LOKASI_PERLU_VERIFIKASI` | Koordinat DB berada di luar geometri; cek provenance/penempatan marker sebelum mengaktifkan overlay. |

## Poligon simulasi

- Berkas simulasi sebelumnya dipertahankan, tidak dicampur ke aset BIG resmi. Parser Flutter menandai dua format secara terpisah; bila ada overlay BIG terverifikasi untuk gunung terpilih, overlay simulasi untuk nama yang sama tidak ditampilkan.
- Disclaimer simulasi tetap terlihat hanya saat overlay simulasi sedang dipakai. Poligon BIG ditampilkan dengan label zona BIG, tahun data, dan catatan bahwa geometri digeneralisasi serta tidak menggantikan informasi PVMBG/BPBD terbaru.

## Perubahan dan pemeriksaan

- Aset baru: `ranah_mobile/assets/geojson/ranah_krb_big_terverifikasi.geojson`.
- Laporan: `docs/audit_krb_2026-10-25/` (CSV, JSON, Markdown, dan salinan GeoJSON terverifikasi).
- Database, koordinat, dan migrasi tidak diubah.
- Tes/analyze dijalankan setelah integrasi aplikasi; hasil dicatat pada laporan pekerjaan Codex.
