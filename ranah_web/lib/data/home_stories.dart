class HomeStory {
  const HomeStory({
    required this.id,
    required this.category,
    required this.title,
    required this.date,
    required this.image,
    required this.color,
    required this.summary,
    required this.content,
    this.heroImage,
    this.source,
  });

  final String id;
  final String category;
  final String title;
  final String date;
  final String image;
  final int color;
  final String summary;
  final String content;
  final String? heroImage;
  final String? source;
}

/// Local demonstration content shared by Home, News, and News Detail.
/// None of these entries represents verified or current reporting.
const newsStories = <HomeStory>[
  HomeStory(
    id: 'demo-eruption',
    category: 'ERUPSI',
    title: 'Contoh Berita: Informasi Aktivitas Erupsi Gunung',
    date: '24 September 2026',
    image: 'assets/images/news_eruption.png',
    heroImage: 'assets/images/home_hero.png',
    color: 0xFFE92C2D,
    summary: 'Contoh ringkasan informasi aktivitas gunung api untuk kebutuhan demonstrasi tampilan.',
    content: 'Ini adalah isi berita demonstrasi untuk pengujian tampilan halaman RANAH. Teks ini tidak menjelaskan kejadian nyata dan tidak berasal dari laporan resmi. Informasi aktivitas, dampak, dan tindak lanjut harus diisi dari sumber yang telah diverifikasi sebelum aplikasi digunakan untuk publik.',
  ),
  HomeStory(
    id: 'demo-shelter',
    category: 'PENGUNGSIAN',
    title: 'Contoh Berita: Informasi Posko Pengungsian',
    date: '20 September 2026',
    image: 'assets/images/news_shelter.png',
    color: 0xFFF39A00,
    summary: 'Contoh informasi posko dan dukungan pengungsian yang ditampilkan sebagai data demonstrasi.',
    content: 'Halaman ini menggunakan konten lokal contoh untuk memperlihatkan susunan berita, tanggal, dan gambar. Nama lokasi, kapasitas, ketersediaan bantuan, serta informasi operasional posko tidak dicantumkan karena belum tersedia sebagai data terverifikasi.',
  ),
  HomeStory(
    id: 'demo-aid',
    category: 'BANTUAN',
    title: 'Contoh Berita: Informasi Bantuan Kebencanaan',
    date: '20 September 2026',
    image: 'assets/images/news_aid.png',
    color: 0xFF74839A,
    summary: 'Contoh informasi bantuan untuk menggambarkan tampilan kategori berita bantuan.',
    content: 'Ini merupakan konten simulasi. Rincian bantuan, penyelenggara, jumlah donasi, dan penerima tidak tersedia dalam data sumber, sehingga tidak ditampilkan sebagai fakta atau informasi resmi.',
  ),
];

const homeStories = newsStories;
const homeHighlights = newsStories;
