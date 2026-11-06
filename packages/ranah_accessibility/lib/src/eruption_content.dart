class ActionGuide {
  const ActionGuide(this.id, this.title, this.steps);
  final String id;
  final String title;
  final List<String> steps;
}

const eruptionGuides = [
  ActionGuide('ash', 'Terkena hujan abu', [
    'Ikuti arahan petugas. Jika belum diminta mengungsi, berlindung di bangunan yang layak dan tutup pintu serta jendela.',
    'Jika harus berada di luar, gunakan masker yang sesuai dan pelindung mata. Kurangi paparan abu.',
    'Jangan mendekati kawah, zona yang ditutup, lembah, atau aliran sungai yang berhulu di gunung.',
    'Jika sesak atau membutuhkan pertolongan, hubungi layanan medis. Jangan menunda mencari bantuan demi menggunakan aplikasi.',
  ]),
  ActionGuide('evacuate', 'Ada arahan mengungsi', [
    'Segera ikuti arahan petugas dan tujuan evakuasi yang ditetapkan untuk wilayah Anda.',
    'Ambil obat dan perlengkapan penting hanya jika terjangkau tanpa menunda keberangkatan.',
    'Gunakan jalur yang ditetapkan. Jauhi lembah, aliran sungai, dan jalur yang ditutup; jangan memilih jalan pintas.',
    'Lapor kepada petugas saat tiba di pengungsian. Jangan kembali sebelum diperbolehkan.',
  ]),
  ActionGuide('help', 'Butuh bantuan bergerak', [
    'Sampaikan posisi dan kebutuhan pendampingan kepada petugas atau orang di sekitar Anda.',
    'Hubungi kontak bantuan yang tersedia. Sebutkan patokan lokasi dan kendala bergerak.',
    'Ikuti petunjuk penjemputan dari petugas. RANAH belum terhubung ke layanan penjemputan atau pengiriman bantuan.',
  ]),
  ActionGuide('shelter', 'Sudah di pengungsian', [
    'Lapor kepada petugas posko dan sampaikan kebutuhan obat atau pendampingan.',
    'Ikuti informasi resmi. Lindungi makanan dan air dari abu serta jaga kebersihan.',
    'Jauhi sungai dan aliran lahar, termasuk setelah erupsi. Kembali hanya setelah diperbolehkan petugas.',
  ]),
];

const preparednessChecklist = [
  'Masker dan pelindung mata',
  'Obat pribadi dan kebutuhan aksesibilitas',
  'Air minum dan makanan siap konsumsi',
  'Dokumen penting terlindungi',
  'Kontak dan tujuan evakuasi dari petugas setempat',
  'Baterai dan penerangan',
];

class TrainingQuestion {
  const TrainingQuestion(
    this.question,
    this.options,
    this.correct,
    this.explanation,
  );
  final String question;
  final List<String> options;
  final int correct;
  final String explanation;
}

const eruptionTraining = [
  TrainingQuestion(
    'Hujan abu turun. Petugas belum meminta Anda mengungsi. Apa tindakan yang sesuai?',
    [
      'Keluar mendekati gunung untuk melihat',
      'Berlindung di bangunan layak, mengurangi abu masuk, dan mengikuti arahan resmi',
    ],
    1,
    'Kurangi paparan abu dan ikuti arahan resmi. Jangan mendekati kawasan yang ditutup.',
  ),
  TrainingQuestion(
    'Ada arahan resmi mengungsi. Barang Anda belum seluruhnya dikemas.',
    [
      'Ikuti arahan; ambil yang penting tanpa menunda',
      'Menunggu semua barang selesai dikemas',
    ],
    0,
    'Persiapan barang tidak boleh menunda keberangkatan ketika diarahkan mengungsi.',
  ),
  TrainingQuestion(
    'Jalur yang ditetapkan ditutup petugas. Ada jalan pintas melalui sungai.',
    ['Gunakan jalan pintas', 'Minta arahan jalur pengganti dari petugas'],
    1,
    'Aliran sungai dan lembah dapat dilalui lahar. Jalur pengganti perlu mengikuti arahan petugas.',
  ),
];

bool isEruptionContent(String category) => RegExp(
  r'erupsi|gunung|vulkan|lahar',
  caseSensitive: false,
).hasMatch(category);
