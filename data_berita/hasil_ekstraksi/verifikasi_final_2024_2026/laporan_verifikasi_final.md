# Laporan Verifikasi Final Data BNPB 2024–2026

## Ringkasan hasil

- Semua **48 kandidat** dari hasil revisi ditelusuri kembali menurut ID: **16 berita/tindakan** dan **32 statistik agregat**. Semua ID unik dipertahankan.
- **0 kandidat dinyatakan LAYAK_PUBLIKASI**. Penelusuran ini memakai buletin PDF dan kutipan sumber yang dirujuknya, bukan verifikasi independen terhadap BNPB/BPBD.
- Status 16 berita/tindakan: **10 LAYAK_DENGAN_CATATAN**, **5 PERLU_VERIFIKASI**, **1 PENANGANAN_BENCANA**.
- Status 32 statistik: **25 STATISTIK_AGREGAT** (kategori konten; tidak otomatis berarti angka tervalidasi visual) dan **7 PERLU_VERIFIKASI**.
- Dari **18 isu awal**, 10 dapat dijelaskan dengan bukti halaman sumber dan 8 masih terbuka. Pemeriksaan halaman menemukan **2 konflik tambahan** (Banjarnegara dan statistik kematian September 2024); total isu yang dinilai menjadi **20**, dengan **10 dijelaskan** dan **10 belum terselesaikan**.
- Tidak ada duplikasi kejadian yang dapat dibuktikan. Dua kandidat statistik Februari 2024 tetap sebagai snapshot terpisah, dengan kedua ID asli.

## Jumlah kandidat yang selesai dan bermasalah

“Selesai diverifikasi” di sini berarti isu/field yang diperiksa dapat dipetakan ke halaman PDF atau konflik dicatat. Ini tidak sama dengan validasi resmi/independen atau kesiapan publikasi. Semua 48 kandidat sudah diberi status akhir; tidak ada kandidat yang sepenuhnya lolos sebagai `LAYAK_PUBLIKASI`. Sepuluh berita berstatus layak dengan catatan dapat dipertimbangkan untuk arsip setelah atribusi buletin dan keterbatasannya disimpan. Lima berita dan tujuh statistik tetap memerlukan tindak lanjut; satu item adalah tindakan penanganan, bukan berita kejadian.

## Status akhir

| Kelompok | Status akhir | Jumlah |
|---|---|---:|
| Berita/tindakan | LAYAK_DENGAN_CATATAN | 10 |
| Berita/tindakan | PENANGANAN_BENCANA | 1 |
| Berita/tindakan | PERLU_VERIFIKASI | 5 |
| Statistik | PERLU_VERIFIKASI | 7 |
| Statistik | STATISTIK_AGREGAT | 25 |

## Kandidat yang dapat dipertimbangkan untuk impor

**Sepuluh kandidat `LAYAK_DENGAN_CATATAN`** pada berita CSV dapat masuk antrean pertimbangan impor arsip dengan `sumber=Buletin Info Bencana BNPB` dan atribusi laporan BPBD jika disebut. Rujukan halaman, cakupan wilayah, tanggal kejadian vs update, serta catatan verifikasi harus ikut disimpan. Status ini bukan persetujuan publikasi otomatis. Kota Padang tidak memiliki kandidat kejadian individual dengan dampak lokal terukur; catatan distribusi air Padang adalah `PENANGANAN_BENCANA` dan tidak disarankan masuk tabel berita kejadian.
**Statistik agregat tidak disarankan diimpor ke tabel berita kejadian individual.** Pisahkan sebagai statistik/arsip agregat. Tujuh baris status `PERLU_VERIFIKASI` harus ditahan; 25 baris lain masih memerlukan pemeriksaan visual angka sebelum diperlakukan sebagai dataset numerik tervalidasi.

## Penilaian 18 isu awal dan 2 temuan tambahan

| Isu | Hasil | Halaman fisik |
|---|---|---:|
| Maret 2024: angka meninggal 28 vs 25 | BELUM_TERSELESAI | `10-11` |
| Statistik Februari 2024: dua dokumen berbeda | BELUM_TERSELESAI | `3; 3` |
| Metadata edisi September 2024: daftar isi menyebut Juli | DIJELASKAN_DENGAN_BUKTI_PDF | `2-3` |
| Metadata edisi Oktober 2024: masthead menyebut April | DIJELASKAN_DENGAN_BUKTI_PDF | `1-3` |
| Metadata edisi Maret 2025: daftar isi menulis 2024 | DIJELASKAN_DENGAN_BUKTI_PDF | `1-3` |
| Cutoff statistik Desember 2025 tercetak 5 Januari 2025 | BELUM_TERSELESAI | `3` |
| Tebing Tinggi: judul menyebut Sumatera Barat, isi menyebut Sumut | DIJELASKAN_DENGAN_BUKTI_PDF | `4` |
| Pacet: salah tahun pada update dan status korban | BELUM_TERSELESAI | `6-9` |
| Juli 2026: total kejadian 232 vs 165 | BELUM_TERSELESAI | `3` |
| Maret 2026: meninggal 34 pada tabel vs 31 pada narasi | BELUM_TERSELESAI | `3` |
| Juni 2025: lapisan ekstraksi rusak | BELUM_TERSELESAI | `6,9,15,21,26,28-29` |
| Agam: tanggal kejadian dan tanggal update terpisah; laporan BPBD dikutip | DIJELASKAN_DENGAN_BUKTI_PDF | `20-21` |
| Dampak Sumbar agregat tidak boleh jadi dampak Kota Padang | DIJELASKAN_DENGAN_BUKTI_PDF | `10-12; 7-9` |
| Distribusi air BPBD Padang adalah tindakan respons, bukan peristiwa | DIJELASKAN_DENGAN_BUKTI_PDF | `10 (footer P.9)` |
| Tapanuli Selatan: sumber menulis “18 Meil 2026” | BELUM_TERSELESAI | `22-23` |
| Agam: update 6 Mei tidak menggantikan tanggal kejadian 5 Mei | DIJELASKAN_DENGAN_BUKTI_PDF | `20-21` |
| Tanggal 11 Mei hanya disebut untuk Padang Panjang dan Agam | DIJELASKAN_DENGAN_BUKTI_PDF | `7` |
| Tingkat administrasi Padang Panjang salah tulis dalam satu kalimat | DIJELASKAN_DENGAN_BUKTI_PDF | `7` |
| Banjarnegara: angka dampak dan kronologi berbeda antarhalaman | BELUM_TERSELESAI | `9-11` |
| September 2024: kematian 22 di tabel vs 21 di narasi | BELUM_TERSELESAI | `3` |

## Konflik yang belum terselesaikan

- **Maret 2024: angka meninggal 28 vs 25** — kandidat `BNPB-2024-03-SUMBAR-001`, `data_berita/BNPB/2024/info_bencana_Maret.pdf`, halaman 10-11. Hal. 10 satu bagian menyebut 28 meninggal; bagian lanjutan pada halaman yang sama menyebut 25. Hal. 11 infografik adalah snapshot per 16 Maret. Tidak memilih salah satu angka.
- **Statistik Februari 2024: dua dokumen berbeda** — kandidat `BNPB-2024-02-AGREGAT-202402;BNPB-2024-03-AGREGAT-202402`, `data_berita/BNPB/2024/info_bencana_Februari.issn edit.pdf; data_berita/BNPB/2024/info_bencana_Maret.pdf`, halaman 3; 3. PDF Februari: 173 kejadian, 30 meninggal, 81 luka, 444.769 gabungan, 2.334 rumah rusak. PDF Maret halaman statistik berjudul Februari: tabel 185 kejadian, 66 meninggal, 79 luka, 1.346.155 gabungan, 22.944 rumah rusak; cutoff sama 1 Maret.
- **Cutoff statistik Desember 2025 tercetak 5 Januari 2025** — kandidat `BNPB-2025-12-AGREGAT-202512`, `data_berita/BNPB/2025/buletin-info-bencana-desember-2025.pdf`, halaman 3. Edisi/statistik dan narasi menyebut Desember 2025. Catatan kaki halaman statistik menyebut data per 5 Januari 2025.
- **Pacet: salah tahun pada update dan status korban** — kandidat `BNPB-2025-04-MOJOKERTO-LANDSLIDE-001`, `data_berita/BNPB/2025/buletin-info-bencana-april-2025.pdf`, halaman 6-9. Kejadian disebut 3 April 2025 11.15; evakuasi 3–4 April menemukan 1 orang hari pertama dan 9 lainnya hari kedua. Halaman 9 menulis “hingga saat ini (6 Mei 2024)” setelah update 24 April 2025; status akhir korban tidak dinyatakan cukup jelas.
- **Juli 2026: total kejadian 232 vs 165** — kandidat `BNPB-2026-07-AGREGAT-202607`, `data_berita/BNPB/2026/buletin-info-bencana-juli-2026.pdf`, halaman 3. Narasi statistik menyebut 232 total kejadian. Tabel menampilkan 165 dan teks/grafik karhutla menyebut 165 kejadian karhutla; cutoff tertulis 7 Juni 2026.
- **Maret 2026: meninggal 34 pada tabel vs 31 pada narasi** — kandidat `BNPB-2026-03-AGREGAT-202603`, `data_berita/BNPB/2026/buletin-info-bencana-maret-2026.pdf`, halaman 3. Tabel statistik menyebut 34 meninggal. Narasi pada halaman yang sama menyebut 31 meninggal.
- **Juni 2025: lapisan ekstraksi rusak** — kandidat `BNPB-2025-06-AGREGAT-202506`, `data_berita/BNPB/2025/buletin-info-bencana-juni-2025.pdf`, halaman 6,9,15,21,26,28-29. Halaman 6,9,15,21,26 memuat karakter pengganti/kerusakan ekstraksi; halaman 28 hanya sedikit teks; halaman 29 kosong. pdftotext dapat membaca sebagian konten tetapi tidak cukup untuk menyatakan semua statistik pada bagian itu benar; OCR/inspeksi visual halaman tersebut belum dilakukan.
- **Tapanuli Selatan: sumber menulis “18 Meil 2026”** — kandidat `BNPB-2026-05-TAPSEL-LANDSLIDE-001`, `data_berita/BNPB/2026/buletin-info-bencana-mei-2026.pdf`, halaman 22-23. Halaman 22 menyebut tanggal literal “18 Meil 2026”. Halaman 23 menyebut laporan BPBD Rabu 20 Mei dan dua meninggal; tanggal kejadian tidak dinormalisasi.
- **Banjarnegara: angka dampak dan kronologi berbeda antarhalaman** — kandidat `BNPB-2025-11-BANJARNEGARA-LANDSLIDE-001`, `data_berita/BNPB/2025/buletin-info-bencana-november-2025.pdf`, halaman 9-11. Hal.9: 21 meninggal, 2 hilang, 73 luka, 1.058 mengungsi, 16 rumah rusak berat. Hal.10: 17 meninggal/11 hilang setelah pencarian; hal.11: 4 luka, 1.019 mengungsi, 182 rumah rusak (54 berat/128 ringan). Ada tanggal “25 Desember setelah 10 hari pencarian” yang tidak selaras dengan kronologi.
- **September 2024: kematian 22 di tabel vs 21 di narasi** — kandidat `BNPB-2024-09-AGREGAT-202409`, `data_berita/BNPB/2024/info_bencana_September.issn.pdf`, halaman 3. Tabel statistik halaman 3 menyebut 22 meninggal. Narasi halaman 3 menyebut 21 meninggal; angka dikosongkan pada data final.

## Temuan Sumatera Barat dan Kota Padang

- Maret 2024: PDF halaman 10 menampilkan 28 meninggal pada satu bagian dan 25 pada bagian lain; empat hilang dan 238.338 terdampak adalah angka regional. Halaman 11 mencantumkan Kota Padang di antara 11 wilayah, tetapi tidak ada rincian dampak khusus Padang.
- Mei 2024: halaman 7 menyebut Lubuk Kilangan, Kota Padang di antara 25 kecamatan/6 kabupaten-kota. Angka 62 meninggal, 10 hilang, 51 luka, 3.595 mengungsi dan kerusakan rumah merupakan rekap Sumbar per 24 Mei. Tanggal 11 Mei dan jam terkait Padang Panjang/Agam, bukan tanggal terverifikasi khusus Lubuk Kilangan.
- Agam Mei 2026: kejadian 5 Mei dan pembaruan hingga 6 Mei terpisah; kutipan sumber adalah BPBD Agam yang dibawa buletin. Catatan dampak 1 meninggal, 6 luka, 29 mengungsi dan 3 rumah terdampak reruntuhan dapat dipertimbangkan sebagai regional dengan atribusi.
- Distribusi 5.000 liter air oleh BPBD Kota Padang tercantum pada halaman 10 buletin September 2024. Tidak disebut tanggal/kaitan ke kejadian tertentu; dicatat sebagai kegiatan penanganan, bukan peristiwa bencana individual.
- Tebing Tinggi: halaman 4 mengandung judul “Sumatera Barat”, namun teks dan keterangan foto menyebut Provinsi Sumut; keluaran menggunakan Sumatera Utara disertai catatan sumber salah tulis. Padang Panjang pada halaman 7 juga salah disebut “Kabupaten” pada satu kalimat, sementara konteks lain di halaman sama menyebut Kota dan wali kota.

## Halaman yang masih membutuhkan pemeriksaan manual

- Juni 2025, halaman fisik 6, 9, 15, 21, 26, 28, 29: lapisan teks berisi karakter pengganti atau tidak memadai. Pemeriksaan via `pdftotext` saja tidak cukup. Belum ada OCR atau pemeriksaan visual ulang halaman-halaman ini; statistik terkait tetap `PERLU_VERIFIKASI`.
- Nilai 25 statistik berstatus `STATISTIK_AGREGAT` tetap terpisah dari artikel kejadian, tetapi angka setiap halaman statistik belum seluruhnya dicocokkan visual satu per satu. Jangan tafsirkan label jenis konten sebagai sertifikat akurasi.
- Metadata publikasi/URL sumber tidak ditambahkan karena tidak terbukti pada PDF yang ditinjau. Data update/cutoff tidak diubah menjadi tanggal publikasi.

## Batas verifikasi dan pekerjaan berikutnya

Berkas PDF adalah salinan lokal buletin, dan beberapa artikel mengutip BPBD atau instansi lain. Pemeriksaan membuktikan apa yang tertulis di salinan tersebut, bukan keaslian/finalitas edisi atau kebenaran independen setiap angka. Rentang PDF tidak membuktikan inventaris seluruh kejadian BNPB 2024–2026. Sebelum impor: klarifikasi 10 isu tersisa ke sumber primer atau revisi resmi, lakukan pemeriksaan visual/manual untuk halaman rusak Juni 2025, validasi angka statistik yang akan dipakai, dan pertahankan jejak PDF/halaman/atribusi di skema tujuan.
