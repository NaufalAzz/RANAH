# Laporan Seleksi Tahap 3 — Arsip Berita Bencana RANAH

## Ringkasan jumlah

- Total kandidat diseleksi dan dipertahankan: **48**.
- Prioritas 1, Sumatera Barat: **5** kandidat.
- Kandidat kejadian/tindakan dari provinsi lain di Indonesia: **10**.
- Statistik agregat nasional: **32** (termasuk dalam prioritas 2 Indonesia karena cakupannya nasional, tetapi tidak dihitung sebagai “di luar Sumbar”).
- Prioritas 2 Indonesia total, termasuk statistik nasional: **42**.
- Status PERLU_VERIFIKASI: **41**.
- Status LAYAK_DITINJAU_PUBLIKASI: **7**.
- Lokasi administratif belum dapat ditetapkan: **1** kandidat.

Jumlah wilayah dibuat saling jelas: 5 kandidat Sumbar + 10 kejadian/tindakan dari provinsi lain + 32 rekap nasional + 1 lokasi yang belum terpastikan = 48. Statistik nasional tidak dianggap sebagai statistik di luar Sumbar karena cakupannya meliputi Indonesia, termasuk Sumbar.

## Aturan klasifikasi

- Kolom provinsi dan kabupaten/kota yang sudah ada di Tahap 2 dipertahankan, tidak digandakan.
- Sumatera Barat, termasuk Kota Padang, memakai PRIORITAS_1_SUMBAR. Kota Padang tidak diberi kategori prioritas tersendiri.
- Provinsi Indonesia lain yang disebut eksplisit memakai PRIORITAS_2_INDONESIA. Statistik yang secara eksplisit berskala Indonesia juga masuk prioritas 2 sebagai cakupan nasional.
- Kandidat dengan provinsi tidak pasti dan bukan statistik nasional memakai BELUM_DITETAPKAN.
- Status PERLU_VERIFIKASI diberikan untuk konflik penting, kandidat Tahap 1 yang masih perlu pemeriksaan, dan statistik yang angkanya belum dicocokkan visual satu per satu.
- LAYAK_DITINJAU_PUBLIKASI berarti layak diteruskan ke pemeriksaan editorial berikutnya. Status tersebut tidak menyatakan berita siap terbit.
- Tidak ada kandidat yang dihapus: semuanya masih terlacak dengan ID dan bukti halaman dari Tahap 2.

## Kandidat prioritas Sumatera Barat

| ID | Kandidat | Jenis dan cakupan | Status |
|---|---|---|---|
| BNPB-2025-11-SUMBAR-001 | Penanganan Bencana Banjir dan Tanah Longsor Provinsi Sumatera Barat | kejadian_individual; Tidak dirinci dalam bagian ini | PERLU_VERIFIKASI |
| BNPB-2026-05-AGAM-LANDSLIDE-001 | Tanah Longsor di Agam, Provinsi Sumatera Barat | kejadian_individual; Kabupaten Agam | PERLU_VERIFIKASI |
| BNPB-2024-03-SUMBAR-001 | Banjir dan Longsor Provinsi Sumatera Barat | kejadian_individual; 11 kabupaten/kota; daftar pada sumber mencakup Kota Padang | PERLU_VERIFIKASI |
| BNPB-2024-05-SUMBAR-001 | Banjir dan Tanah Longsor di Provinsi Sumatera Barat (termasuk banjir lahar dingin) | kejadian_individual; Kabupaten Padang Panjang, Kabupaten Agam, Kabupaten Tanah Datar, Kabupaten Padang Pariaman, Kabupaten Lima Puluh Kota; cakupan enam kabupaten/kota | PERLU_VERIFIKASI |
| BNPB-2024-09-PADANG-DRY-001 | Distribusi air bersih oleh BPBD Kota Padang (bagian “Kekeringan di Indonesia”) | tindakan_penanganan; Kota Padang | PERLU_VERIFIKASI |

Statistik nasional dengan baris provinsi kosong tidak dianggap kandidat berlokasi belum pasti: sumber Tahap 2 mengidentifikasikannya sebagai rekap Indonesia. Satu kandidat Tebing Tinggi memiliki nama kota, tetapi klaim provinsinya berkonflik; karena itu prioritasnya BELUM_DITETAPKAN dan seleksinya PERLU_VERIFIKASI.


## Konflik yang masih terbuka

| Topik | Konflik dan dampak seleksi |
|---|---|
| Sumbar Maret 2024 | 28 vs 25 korban meninggal dalam artikel yang sama; jangan pilih salah satu. |
| Statistik Februari 2024 | Dua PDF dengan periode dan cutoff sama memberikan angka statistik berbeda. |
| Edisi September 2024 | Daftar isi menyebut Juli, sampul/masthead dan halaman statistik menyebut September. |
| Edisi Oktober 2024 | Masthead internal menyebut April, sampul dan isi menyebut Oktober. |
| Edisi Maret 2025 | Daftar isi menyebut Maret 2024, sampul dan isi menyebut Maret 2025. |
| Statistik Desember 2025 | Cutoff halaman statistik tercantum 5 Januari 2025; tidak diasumsikan maksudnya 2026. |
| Banjir Tebing Tinggi | Judul menyebut Kota Tebing Tinggi, Sumatera Barat; provinsi dikosongkan sampai konflik lokasi diverifikasi. |
| Longsor Pacet April 2025 | Ada teks “6 Mei 2024” yang tidak cocok dengan kronologi 2025 dan status akhir seluruh 10 korban tidak jelas. |

PDF Juni 2025 juga masih memiliki ekstraksi teks rusak pada beberapa halaman. Ini adalah keterbatasan sumber/ekstraksi, bukan konflik angka yang telah diselesaikan.


## Kandidat paling layak untuk tahap berikutnya

1. **BNPB-2026-05-AGAM-LANDSLIDE-001 — Tanah longsor di Agam, Sumatera Barat.** Ini kandidat pertama untuk pemeriksaan lanjutan karena lokasi Sumbar dinyatakan eksplisit, tanggal 5 Mei 2026 disebut, dan dua nagari/kecamatan disebut secara spesifik. Tahap 2 merujuk buletin-info-bencana-mei-2026.pdf halaman fisik 20–21. Teks PDF menyatakan satu korban meninggal, enam luka, 29 mengungsi, serta tiga rumah terdampak. Angka dan halaman perlu dicocokkan visual sebelum dipakai; status saat ini tetap PERLU_VERIFIKASI.
2. **BNPB-2025-11-SUMBAR-001 — rangkaian banjir/longsor Sumatera Barat.** Relevan untuk prioritas wilayah dan memiliki halaman sumber 14–16 di buletin Desember 2025. Namun lokasi kota/kabupaten dan tanggal kejadian rinci tidak tersedia pada kandidat Tahap 2; proses berikutnya perlu memastikan cakupan tiap angka sebelum seleksi publikasi.
3. **BNPB-2024-03-SUMBAR-001 dan BNPB-2024-05-SUMBAR-001** tetap penting karena menyebut Sumatera Barat dan (untuk Maret) Kota Padang/Lubuk Kilangan (Mei). Keduanya bukan pilihan pertama untuk kurasi: artikel Maret menyebut Kota Padang sebagai salah satu wilayah Sumbar, sedangkan artikel Mei menyebut Kecamatan Lubuk Kilangan. Angka dampak Mei berskala provinsi dan tanggal 11 Mei tidak terbukti berlaku untuk seluruh wilayah.

Di antara tujuh kandidat berstatus LAYAK_DITINJAU_PUBLIKASI, kandidat tersebut tersebar di luar Sumbar; mereka dapat masuk antrian editorial wilayah Indonesia setelah prioritas Sumbar diproses. Tidak ada kandidat yang dinyatakan siap dipublikasikan.

## Batasan

- Tahap 3 menyeleksi isi dan bukti Tahap 2; tidak melakukan autentikasi independen setiap PDF terhadap situs BNPB.
- Tahap 2 hanya mengekstrak 9 artikel tambahan dan belum membaca semua artikel pada 32 PDF satu per satu.
- Statistik agregat tetap terpisah dari berita kejadian individual. Angka gabungan terdampak dan mengungsi tidak dipecah.
- Pemeriksaan visual menyeluruh semua angka belum dilakukan. Statistik nasional tetap PERLU_VERIFIKASI.
- Tanggal publikasi tidak disimpulkan dari bulan edisi. URL publikasi, tanggal, lokasi, atau angka yang tidak ada di bukti tidak ditambahkan.
- Tidak ada klaim arsip lengkap atau data resmi siap publikasi.

## Keluaran

- data_berita/hasil_ekstraksi/hasil_seleksi_tahap3.csv
- data_berita/hasil_ekstraksi/hasil_seleksi_tahap3.json
- data_berita/laporan_validasi/laporan_seleksi_tahap3.md

Semua 48 ID dari Tahap 2 tersedia pada CSV dan JSON Tahap 3. Tidak ada perubahan ke kode, database, PDF, atau keluaran Tahap 1 dan Tahap 2.
