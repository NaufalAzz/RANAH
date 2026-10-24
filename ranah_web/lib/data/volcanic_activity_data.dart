class VolcanoActivitySample {
  const VolcanoActivitySample({
    required this.name,
    required this.province,
    required this.level,
    required this.image,
  });

  final String name;
  final String province;
  final int level;
  final String image;
}

class ActivityLevelSample {
  const ActivityLevelSample({
    required this.level,
    required this.name,
    required this.color,
    required this.description,
  });

  final int level;
  final String name;
  final int color;
  final String description;
}

const activityLevelSamples = <ActivityLevelSample>[
  ActivityLevelSample(
    level: 4,
    name: 'Awas',
    color: 0xFFE53935,
    description: 'Contoh status Level IV untuk rancangan antarmuka.',
  ),
  ActivityLevelSample(
    level: 3,
    name: 'Siaga',
    color: 0xFFF27822,
    description: 'Contoh aktivitas meningkat; bukan informasi terkini.',
  ),
  ActivityLevelSample(
    level: 2,
    name: 'Waspada',
    color: 0xFFFFB51B,
    description: 'Contoh aktivitas di atas tingkat normal.',
  ),
  ActivityLevelSample(
    level: 1,
    name: 'Normal',
    color: 0xFF39B85B,
    description: 'Contoh aktivitas dasar untuk tampilan daftar.',
  ),
];

// Semua level dan provinsi di daftar ini hanya data demonstrasi.
const volcanicActivitySamples = <VolcanoActivitySample>[
  VolcanoActivitySample(
    name: 'Gunung Merapi',
    province: 'DI Yogyakarta dan Jawa Tengah',
    level: 3,
    image: 'assets/images/activity_merapi.png',
  ),
  VolcanoActivitySample(
    name: 'Gunung Semeru',
    province: 'Jawa Timur',
    level: 3,
    image: 'assets/images/activity_semeru.png',
  ),
  VolcanoActivitySample(
    name: 'Gunung Anak Krakatau',
    province: 'Lampung',
    level: 3,
    image: 'assets/images/activity_krakatau.png',
  ),
  VolcanoActivitySample(
    name: 'Gunung Bromo',
    province: 'Jawa Timur',
    level: 2,
    image: 'assets/images/activity_bromo.png',
  ),
  VolcanoActivitySample(
    name: 'Gunung Rinjani',
    province: 'Nusa Tenggara Barat',
    level: 2,
    image: 'assets/images/activity_rinjani.png',
  ),
  VolcanoActivitySample(
    name: 'Gunung Marapi',
    province: 'Sumatera Barat (contoh)',
    level: 2,
    image: 'assets/images/volcano_report_photo.png',
  ),
  VolcanoActivitySample(
    name: 'Gunung Talang',
    province: 'Sumatera Barat (contoh)',
    level: 1,
    image: 'assets/images/news_eruption.png',
  ),
];

const volcanicDescriptions = <int, String>{
  4: 'Erupsi besar segera atau sedang terjadi. Evakuasi sesuai arahan petugas.',
  3: 'Peningkatan aktivitas nyata. Potensi erupsi dapat terjadi sewaktu-waktu.',
  2: 'Aktivitas meningkat di atas normal. Hindari area sekitar kawah.',
  1: 'Aktivitas dasar, tanpa perubahan signifikan pada contoh data ini.',
};

const sampleVolcanoReportSections = <String, String>{
  'Lokasi Administratif dan Geografis': 'Data administratif dan koordinat contoh belum diverifikasi. Tidak untuk navigasi.',
  'Periode Pengamatan': 'Periode contoh. Tanggal dan hasil pengamatan resmi tidak tersedia pada demo ini.',
  'Klimatologi': 'Placeholder klimatologi untuk contoh tampilan; bukan kondisi cuaca saat ini.',
  'Pengamatan Visual': 'Placeholder pengamatan visual. Tidak menggambarkan kondisi gunung terkini.',
  'Rekomendasi': 'Contoh teks rekomendasi. Ikuti informasi dan arahan resmi PVMBG atau BPBD.',
};
