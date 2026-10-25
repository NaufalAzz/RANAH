# Revisi dan Validasi Data Berita BNPB 2024–2026

## Ringkasan

- Kandidat Tahap 2: **48**; keluaran mempertahankan seluruh **48 ID unik**.
- Berita/penanganan non-statistik: **16**; statistik agregat terpisah: **32**.
- Kandidat `LAYAK_PUBLIKASI`: **0**. Dua kandidat `LAYAK_DENGAN_CATATAN` hanya layak dipertimbangkan sebagai arsip regional dengan atribusi dan keterbatasan ditampilkan; bukan status siap terbit.
- Data khusus Kota Padang: **1 tindakan penanganan**, **0 kejadian individual dengan dampak khusus Kota Padang yang terukur**. Dua berita Sumbar menyebut Padang sebagai bagian dari cakupan multiwilayah, tetapi dampaknya agregat provinsi.
- Arsip sumber yang tersedia: PDF Januari–Desember 2024, Januari–Desember 2025, Januari–Agustus 2026. Ini bukan bukti inventaris kejadian lengkap.

## Jumlah kandidat berita

| Tahun | Jumlah |
|---|---:|
| 2024 | 7 |
| 2025 | 4 |
| 2026 | 5 |

| Jenis konten | Jumlah |
|---|---:|
| KEJADIAN_INDIVIDUAL | 15 |
| PENANGANAN_BENCANA | 1 |

| Status berita | Jumlah |
|---|---:|
| DI LUAR_CAKUPAN_PADANG | 8 |
| LAYAK_DENGAN_CATATAN | 2 |
| PERLU_VERIFIKASI | 6 |

| Status statistik | Jumlah |
|---|---:|
| PERLU_VERIFIKASI | 9 |
| STATISTIK_AGREGAT | 23 |

| Cakupan | Jumlah berita |
|---|---:|
| DI LUAR_CAKUPAN_PADANG | 10 |
| KOTA_PADANG | 1 |
| LOKASI_PROVINSI_BERTENTANGAN | 1 |
| REGIONAL_SUMATERA_BARAT | 4 |

## Kandidat yang dapat dipertimbangkan dengan catatan

- **BNPB-2025-11-SUMBAR-001 — Penanganan Bencana Banjir dan Tanah Longsor Provinsi Sumatera Barat**. Kandidat arsip regional: lokasi provinsi dan angka pembaruan disebut; kabupaten/kota dan tanggal kejadian tepat tidak dirinci. Angka merupakan laporan buletin yang merujuk pembaruan 4 Januari 2026. Bukti: `buletin-info-bencana-desember-2025.pdf`, halaman fisik 14-16.
- **BNPB-2026-05-AGAM-LANDSLIDE-001 — Tanah Longsor di Agam, Provinsi Sumatera Barat**. Kandidat arsip regional; tanggal, lokasi dan dampak tercantum. Buletin mengutip laporan BPBD Agam dan bukan verifikasi independen. Bukti: `buletin-info-bencana-mei-2026.pdf`, halaman fisik 20-21.

## Berita yang perlu verifikasi

- **BNPB-2026-05-TAPSEL-LANDSLIDE-001** — Tanggal kejadian tidak dinormalisasi karena sumber menulis “18 Meil 2026”; 20 Mei adalah tanggal pembaruan BPBD. Sumber: `buletin-info-bencana-mei-2026.pdf`, halaman fisik 22-23.
- **BNPB-2024-03-SUMBAR-001** — Angka meninggal bertentangan dalam artikel (28 dan 25). Angka dampak yang tersedia berskala provinsi/11 daerah dan tidak boleh diatribusikan ke Kota Padang. Sumber: `info_bencana_Maret.pdf`, halaman fisik 10-12.
- **BNPB-2024-05-SUMBAR-001** — Dampak yang dicantumkan adalah agregat provinsi, bukan dampak masing-masing kota/kabupaten. Tanggal 11 Mei hanya terkait uraian Padang Panjang dan Agam; tanggal untuk semua lokasi termasuk Padang tidak dipastikan. Sumber: `info_bencana_Mei.issn.pdf`, halaman fisik 7-9.
- **BNPB-2024-09-PADANG-DRY-001** — Ini tindakan distribusi air bersih BPBD, bukan kejadian bencana individual; tanggal, penerima, dan kaitan dengan kejadian tertentu tidak disebut. Sumber: `info_bencana_September.issn.pdf`, halaman fisik 10.
- **BNPB-2024-10-TEBING-TINGGI-FLOOD-001** — Provinsi kosong karena sumber memiliki konflik identitas/lokasi; tidak disimpulkan dari nama Kota Tebing Tinggi. Sumber: `5. Buletin Info Bencana Oktober 2024.pdf`, halaman fisik 4.
- **BNPB-2025-04-MOJOKERTO-LANDSLIDE-001** — Kronologi memuat teks “6 Mei 2024” setelah kejadian 3 April 2025 dan status akhir korban belum terkonfirmasi pada halaman yang ditinjau. Sumber: `buletin-info-bencana-april-2025.pdf`, halaman fisik 5-8.

## Konflik belum terselesaikan

Tercatat **18 isu** pada CSV konflik; belum ada konflik yang ditandai selesai.
- Angka meninggal Maret 2024 berbeda — `BNPB-2024-03-SUMBAR-001` (info_bencana_Maret.pdf, hlm. 10-11). Tidak memilih angka; simpan sebagai konflik dalam kandidat.
- Dua snapshot statistik Februari 2024 berbeda — `BNPB-2024-02-AGREGAT-202402;BNPB-2024-03-AGREGAT-202402` (info_bencana_Februari.issn edit.pdf; info_bencana_Maret.pdf, hlm. 3; 3). Pertahankan kedua ID; tidak menyimpulkan snapshot mana yang benar.
- Identitas periode edisi September 2024 — `BNPB-2024-09-AGREGAT-202409` (info_bencana_September.issn.pdf, hlm. 2-3). Statistik tetap periode seperti heading halaman statistik; tandai verifikasi edisi.
- Identitas edisi Oktober 2024 — `BNPB-2024-10-AGREGAT-202410` (5. Buletin Info Bencana Oktober 2024.pdf, hlm. 1-3). Pertahankan periode dari sampul/isi; masthead konflik belum selesai.
- Identitas periode Maret 2025 — `BNPB-2025-03-AGREGAT-202503` (buletin-info-bencana-maret-2025.pdf, hlm. 1-3). Tidak mengubah tanggal dari bukti halaman; perlu verifikasi editorial.
- Batas data Desember 2025 tidak konsisten — `BNPB-2025-12-AGREGAT-202512` (buletin-info-bencana-desember-2025.pdf, hlm. 3). Catat tanggal literal; tidak mengasumsikan 2026.
- Provinsi Tebing Tinggi bertentangan/kosong — `BNPB-2024-10-TEBING-TINGGI-FLOOD-001` (5. Buletin Info Bencana Oktober 2024.pdf, hlm. 4). Provinsi dibiarkan kosong; perlu pemeriksaan sumber primer.
- Kronologi dan status korban Pacet — `BNPB-2025-04-MOJOKERTO-LANDSLIDE-001` (buletin-info-bencana-april-2025.pdf, hlm. 5-8). Tanggal kejadian dipertahankan sebagai 3 April dari narasi; korban jiwa tidak ditetapkan.
- Total statistik Juli 2026 konflik — `BNPB-2026-07-AGREGAT-202607` (buletin-info-bencana-juli-2026.pdf, hlm. 3). Jumlah total kejadian dikosongkan; tidak ada angka yang dipilih.
- Korban meninggal statistik Maret 2026 — `BNPB-2026-03-AGREGAT-202603` (buletin-info-bencana-maret-2026.pdf, hlm. 3). Jumlah meninggal dikosongkan; konflik dipertahankan.
- Lapisan ekstraksi PDF Juni 2025 rusak — `BNPB-2025-06-AGREGAT-202506` (buletin-info-bencana-juni-2025.pdf, hlm. 6,9,15,21,26,28-29). Jangan validasi angka halaman tersebut tanpa pemeriksaan visual/OCR manual.
- Atribusi dan tanggal pembaruan Agam — `BNPB-2026-05-AGAM-LANDSLIDE-001` (buletin-info-bencana-mei-2026.pdf, hlm. 20-21). Pisahkan tanggal kejadian/pembaruan dan tampilkan atribusi.
- Dampak regional Sumbar bukan dampak Kota Padang — `BNPB-2024-03-SUMBAR-001;BNPB-2024-05-SUMBAR-001` (info_bencana_Maret.pdf; info_bencana_Mei.issn.pdf, hlm. 10-12; 7-9). Jangan memindahkan angka provinsi ke Kota Padang.
- Distribusi air bersih adalah tindakan penanganan — `BNPB-2024-09-PADANG-DRY-001` (info_bencana_September.issn.pdf, hlm. 10). Klasifikasi PENANGANAN_BENCANA; tidak dijadikan kejadian individual.
- Tanggal kejadian Tapanuli Selatan salah ketik di sumber — `BNPB-2026-05-TAPSEL-LANDSLIDE-001` (buletin-info-bencana-mei-2026.pdf, hlm. 22-23). Tanggal kejadian ISO dikosongkan sampai dikonfirmasi.
- Tanggal kejadian dan update tidak boleh tertukar — `BNPB-2026-05-AGAM-LANDSLIDE-001` (buletin-info-bencana-mei-2026.pdf, hlm. 20-21). Simpan tanggal kejadian 5 Mei dan pembaruan 6 Mei terpisah.
- Tanggal 11 Mei tidak berlaku untuk seluruh lokasi — `BNPB-2024-05-SUMBAR-001` (info_bencana_Mei.issn.pdf, hlm. 7-9). Tanggal kejadian keseluruhan dikosongkan; tanggal Padang spesifik belum terbukti.
- Tingkat administrasi Padang Panjang — `BNPB-2024-05-SUMBAR-001` (info_bencana_Mei.issn.pdf, hlm. 7). Gunakan “Kota Padang Panjang” dan pertahankan daftar lokasi sumber.

## Statistik agregat

Dipisahkan **32** baris statistik nasional dari berita kejadian. Jumlah kejadian hanya diisi bila eksplisit dan telah ditinjau pada baris statistik yang disebut; field dampak gabungan tetap kosong karena skema input tidak menyediakan pemisahan yang andal. Statistik lain belum dicocokkan visual satu per satu.

## Duplikasi dan keterlacakan

Tidak ada kandidat yang dihapus atau digabung. Dua statistik Februari 2024 tetap memiliki ID terpisah karena bukti hanya menunjukkan periode/cutoff serupa dengan nilai yang berbeda; belum cukup untuk menyebut salah satunya duplikat identik. Seluruh 48 ID input dipertahankan sekali dalam keluaran berita+statistik.

## Pemeriksaan visual dan batasan

- Pemeriksaan visual terfokus: Maret 2024 Sumbar (fisik 10–11), Mei 2024 Sumbar (fisik 7), Agam Mei 2026 (fisik 20–21), Tapanuli Selatan Mei 2026 (fisik 22–23), Maret 2026 statistik (fisik 3), dan Juli 2026 statistik (fisik 3). Halaman lainnya mengacu pada hasil ekstraksi Tahap 2; tidak seluruh artikel dalam PDF diperiksa satu per satu.
- Juni 2025: halaman fisik 6, 9, 15, 21, 26 memiliki teks rusak; halaman 28 hanya sedikit karakter dan halaman 29 kosong pada ekstraksi. Memerlukan pemeriksaan visual/OCR manual; OCR tidak dijalankan.
- Tanggal publikasi dan URL sumber PDF tidak ditemukan/terverifikasi pada input, sehingga dibiarkan kosong. Tanggal pembaruan hanya diisi ketika dinyatakan terpisah dalam sumber.
- Kosong berarti tidak tersedia/tidak dipastikan, bukan nol. Nilai agregat tidak diubah menjadi dampak Kota Padang. Dokumen adalah buletin BNPB yang dikoleksi lokal; keluaran ini tidak membuktikan autentisitas versi final atau validasi independen atas laporan yang dikutip.
- Ringkasan disunting agar mudah dibaca tanpa menambah fakta; halaman PDF adalah indeks fisik mulai dari 1 dan dapat berbeda dari nomor footer cetak.

## Pekerjaan verifikasi tersisa

1. Cocokkan angka seluruh statistik nasional terhadap halaman visual, terutama periode dengan konflik edisi/cutoff. 2. Minta/temukan klarifikasi sumber primer untuk angka kematian Maret 2024 dan provinsi Tebing Tinggi. 3. Periksa visual halaman rusak Juni 2025 bila salinan yang dapat dibaca tersedia. 4. Verifikasi kronologi Pacet dan pembaruan akhir korban. 5. Jangan menerbitkan kandidat regional dengan angka sementara tanpa atribusi tanggal pembaruan yang jelas.
