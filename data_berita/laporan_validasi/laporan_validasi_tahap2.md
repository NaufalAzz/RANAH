# Laporan Validasi Tahap 2 — Arsip Buletin BNPB 2024–2026

## Ringkasan

- Kandidat Tahap 1 ditinjau: **39**.
- Artikel/kandidat baru diekstrak: **9**.
- Jumlah baris keluaran: **48**, seluruh ID unik. Konflik/ketidaksesuaian terbuka: **8 kelompok** (angka Sumbar Maret 2024; statistik Februari 2024; daftar isi September 2024; masthead Oktober 2024; daftar isi Maret 2025; cutoff Desember 2025; provinsi Tebing Tinggi; tanggal/hasil korban Pacet April 2025).
- Sumber lokal: 32 PDF di data_berita/BNPB (2024: 12, 2025: 12, 2026: 8).
- Hasil adalah kandidat berbasis PDF lokal, bukan verifikasi independen atas keaslian/versi final dan bukan persetujuan publikasi.
- Pemeriksaan artikel belum menyeluruh satu per satu pada semua PDF; hasil tidak mengklaim seluruh artikel atau seluruh arsip 2024–2026 sudah diekstrak.

## Folder dan metode pemeriksaan

Folder sumber aktual adalah data_berita/BNPB/. Laporan Tahap 1 menulis BNBP/, yang tidak sesuai dengan folder saat ini. Lapisan teks PDF dibaca memakai pdftotext yang telah tersedia. Tidak ada OCR yang dipasang. Nomor halaman keluaran adalah indeks fisik PDF, bukan nomor cetak footer.

PDF Maret 2024 halaman fisik 10–11 juga diperiksa secara visual: teks memuat angka kematian berbeda, dan infografis mencantumkan 11 kabupaten/kota termasuk Kota Padang.

## Temuan konflik prioritas

| Topik | Bukti pada PDF | Keputusan |
|---|---|---|
| Banjir/longsor Sumbar Maret 2024 | Halaman fisik 10 menyebut 28 meninggal lalu 25 pada paragraf berikutnya. Halaman 11 menampilkan infografis per 16 Maret dan daftar Kota Padang di antara 11 kabupaten/kota. | Belum selesai. Field jumlah meninggal dikosongkan; angka tidak dipilih. Semua angka dampak adalah tingkat provinsi, bukan khusus Padang. |
| Banjir/longsor Sumbar Mei 2024 | Halaman fisik 7 menyebut Padang Panjang pada 11 Mei pukul 22.00 dan Agam pukul 21.00; Lubuk Kilangan, Kota Padang, hanya disebut dalam daftar wilayah. Rekap Pusdalops per 24 Mei adalah provinsi. | Tanggal tunggal dihapus karena tidak terbukti untuk semua lokasi/Padang. Angka dampak dilabeli agregat provinsi. |
| Distribusi air Kota Padang, September 2024 | Halaman fisik 10 menyebut BPBD Kota Padang menyalurkan 5.000 liter air bersih; tanggal dan jumlah penerima tidak disebut. | Direklasifikasi sebagai tindakan penanganan, bukan kejadian/statistik. |
| Edisi Oktober 2024 | Sampul fisik 1: Vol. 5 No. 10 Oktober; masthead fisik 2: Vol. 4 No. 4 April; statistik fisik 3: Oktober. | Konflik berada pada masthead internal, bukan sampul. Catat sebagai konflik editorial. |
| Edisi Maret 2025 | Sampul fisik 1 menyebut Maret 2025; daftar isi fisik 2 menyebut ulasan Maret 2024; isi/statistik menyebut Maret 2025. | Konflik daftar isi dicatat; bukan kesalahan sampul. |
| Edisi September 2024 | Sampul/masthead serta statistik fisik 3 menyebut September; daftar isi fisik 2 menyebut statistik Juli. | Konflik daftar isi dipertahankan terbuka. |
| PDF Juni 2025 | Karakter pengganti muncul pada halaman fisik 6, 9, 15, 21, dan 26; halaman fisik 28 hanya berisi beberapa karakter dan halaman 29 kosong. Halaman awal lain masih terbaca. | Bagian yang korup perlu pemeriksaan visual manual; angka dari teks rusak tidak dipakai. |
| Statistik Desember 2025 | Halaman statistik fisik 3 menyebut cutoff 5 Januari 2025 walau edisi/isi Desember 2025. | Belum selesai; tidak diasumsikan maksudnya 2026. |
| Statistik Februari 2024 | Dua PDF berjudul Februari 2024, cutoff 1 Maret 2024, tapi angka berbeda. File Februari: 173 kejadian, 30 meninggal, 81 luka, gabungan terdampak+mengungsi 444.769, 2.334 rumah rusak. File Maret: 185 kejadian, 66 meninggal, 79 luka, 1.346.155 gabungan, 22.944 rumah rusak. | Kedua snapshot dipertahankan terpisah; belum ada dasar memilih/revisi. |

## Kandidat artikel baru

Tanggal terbit tidak diisi karena bulan edisi bukan bukti tanggal publikasi. Kutipan/catatan bukti lengkap tersedia pada tiap baris CSV/JSON.

| ID | Artikel | Tanggal kejadian | Lokasi yang disebut | PDF dan halaman fisik |
|---|---|---|---|---|
| BNPB-2024-04-RUANG-ERUPSI-001 | Erupsi Gunung Ruang dan evakuasi Pulau Tagulandang | 2024-04-16 | Kabupaten Kepulauan Siau Tagulandang Biaro, Sulawesi Utara | 4. buletin-info-bencana-april-2024.pdf, 5-6 |
| BNPB-2024-10-TEBING-TINGGI-FLOOD-001 | Banjir Kota Tebing Tinggi | 2024-10-09 | Kota Tebing Tinggi | 5. Buletin Info Bencana Oktober 2024.pdf, 4 |
| BNPB-2024-11-LEWOTOBI-ERUPSI-001 | Erupsi Gunung Api Lewotobi Laki-laki | 2024-11-03 | Kabupaten Flores Timur, Nusa Tenggara Timur | info_bencana_November 2024.issn.pdf, 9 |
| BNPB-2024-12-PANDEGLANG-FLOOD-001 | Banjir Kabupaten Pandeglang | 2024-12-02 | Kabupaten Pandeglang, Banten | 6. Info Bencana Desember 2024.pdf, 8 |
| BNPB-2025-04-MOJOKERTO-LANDSLIDE-001 | Tanah longsor di jalur Pacet, Kabupaten Mojokerto | 2025-04-03 | Kabupaten Mojokerto, Jawa Timur | buletin-info-bencana-april-2025.pdf, 5-8 |
| BNPB-2025-04-KAPUAS-MINE-LANDSLIDE-001 | Tanah longsor tambang emas di Kabupaten Kapuas | 2025-04-29 | Kabupaten Kapuas, Kalimantan Tengah | buletin-info-bencana-april-2025.pdf, 9-10 |
| BNPB-2025-11-BANJARNEGARA-LANDSLIDE-001 | Tanah longsor Dusun Situkung, Banjarnegara | 2025-11-16 | Kabupaten Banjarnegara, Jawa Tengah | buletin-info-bencana-november-2025.pdf, 9-11 |
| BNPB-2026-03-BANTARGEBANG-LANDSLIDE-001 | Longsor gunungan sampah TPST Bantargebang | 2026-03-08 | Kota Bekasi, Jawa Barat | buletin-info-bencana-maret-2026.pdf, 7 |
| BNPB-2026-08-MEDAN-EXTREME-WEATHER-001 | Cuaca ekstrem Kota Medan | 2026-08-18 | Kota Medan, Sumatera Utara | buletin-info-bencana-agustus-2026.pdf, 14-15 |

## Cakupan dan batasan ekstraksi

- Kandidat dari Tahap 1 dipertahankan untuk perbandingan. Statistik agregat tetap memerlukan pencocokan visual angka dan tidak berubah menjadi catatan kejadian individual.
- Data gabungan terdampak+mengungsi tidak dipecah. Field kosong berarti tidak dibuktikan atau sengaja dikosongkan karena konflik, bukan nol.
- Sumber PDF lokal menyebut Kota Padang sebagai bagian cakupan Sumbar dalam kandidat Maret dan Lubuk Kilangan dalam artikel Mei; tidak ada angka dampak khusus Kota Padang yang dapat dipisahkan.
- Belum semua artikel dari 32 PDF diperiksa. Penyisiran halaman lanjutan dibutuhkan sebelum menyebut inventaris lengkap.

## Pemeriksaan manual yang masih diperlukan

1. Cocokkan angka grafik/tabel untuk semua statistik bulanan; 32 baris agregat belum disahkan visual satu per satu.
2. Periksa visual halaman fisik 6, 9, 15, 21, 26, dan terutama halaman 28–29 pada buletin-info-bencana-juni-2025.pdf. Tidak memasang OCR/dependensi.
3. Minta klarifikasi/errata untuk angka meninggal 28 vs 25 Sumbar Maret 2024, cutoff Desember 2025, dua snapshot Februari 2024, dan konflik periode daftar isi September 2024.
4. Verifikasi klaim lokasi Kota Tebing Tinggi, Sumatera Barat dari sumber pemerintah lain; kolom provinsi dikosongkan sampai terkonfirmasi.
5. Longsor Pacet April 2025: status akhir seluruh 10 korban tidak jelas pada halaman yang ditinjau; tanggal 6 Mei 2024 pada teks juga bertentangan dengan kronologi 2025.
6. Pastikan versi resmi final untuk setiap PDF dan periksa artikel yang belum ditinjau; sumber URL individual/tanggal publikasi tidak dibuat atau ditebak.

## Berkas keluaran

- data_berita/hasil_ekstraksi/hasil_validasi_tahap2.csv
- data_berita/hasil_ekstraksi/hasil_validasi_tahap2.json
- data_berita/laporan_validasi/laporan_validasi_tahap2.md

PDF sumber dan keluaran Tahap 1 dipertahankan. Tidak ada perubahan Flutter/Laravel/database, migrasi, seeder, impor, atau Git.
