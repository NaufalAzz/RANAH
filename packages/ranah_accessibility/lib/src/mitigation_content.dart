import 'package:flutter/material.dart';

enum GuideScene {
  radio,
  bag,
  mask,
  route,
  shelter,
  river,
  help,
  clean,
  window,
  water,
  meeting,
  vehicle,
}

class GuideSource {
  const GuideSource(
    this.id,
    this.organization,
    this.title,
    this.url,
    this.locator,
  );
  final String id, organization, title, url, locator;
  static const checkedAt = '24 November 2026';
}

const bnpbPreparation = GuideSource(
  'bnpb-preparation',
  'BNPB',
  'Gunung Api',
  'https://bnpb.go.id/index.php/berita/gunung-api',
  'Bagian sebelum letusan; terbit 27 Desember 2017',
);
const bnpbMessages = GuideSource(
  'bnpb-messages',
  'BNPB',
  'Pedoman Sosialisasi Penanggulangan Bencana Nomor 3 Tahun 2024',
  'https://jdih.bnpb.go.id/download-lampiran/pedoman-nomor-3-tahun-2024',
  'Pesan kunci umum dan letusan gunung api, halaman tercetak 28–31',
);
const healthGuide = GuideSource(
  'kemkes-health',
  'Kementerian Kesehatan',
  'Bersahabat dengan Gunung Berapi',
  'https://pusatkrisis.kemkes.go.id/__pub/files47205desain%20buku%20erupsi%20v3.4%20AR%20PRINT.pdf',
  'Pusat Krisis Kesehatan, halaman tercetak 6–7',
);
const bpbdRecovery = GuideSource(
  'bpbd-recovery',
  'BPBD DIY',
  'Tips Bencana Letusan Gunung Api',
  'https://bpbd.jogjaprov.go.id/tips-bencana-letusan-gunung-api',
  'Bagian pascabencana; terbit 9 Mei 2019',
);

const healthTraining = GuideSource(
  'kemkes-cikarang',
  'Kementerian Kesehatan',
  'Penanggulangan Bencana (Gunung Meletus) Berbasis Masyarakat',
  'https://bapelkescikarang.kemkes.go.id/berita/AR101',
  'Balai Pelatihan Kesehatan Cikarang, bagian sebelum, saat, dan setelah letusan',
);
const cdcPreparation = GuideSource(
  'cdc-volcanoes',
  'CDC',
  'Preparing for a Volcanic Eruption',
  'https://www.cdc.gov/volcanoes/safety/index.html',
  'Bagian Prepare for an emergency evacuation dan Prepare to shelter where you are (bahasa Inggris)',
);
const usgsAsh = GuideSource(
  'usgs-ash',
  'USGS',
  'What do you do when a volcano erupts?',
  'https://www.usgs.gov/observatories/cvo/what-do-you-do-when-volcano-erupts-actions-take',
  'Bagian If ash is falling (bahasa Inggris)',
);

class IllustratedGuideStep {
  const IllustratedGuideStep(
    this.title,
    this.action,
    this.reason,
    this.avoid,
    this.scene,
    this.caption,
    this.source,
  );
  final String title, action, reason, avoid, caption;
  final GuideScene scene;
  final GuideSource source;
}

class MitigationLesson {
  const MitigationLesson(
    this.id,
    this.title,
    this.subtitle,
    this.accent,
    this.icon,
    this.takeaway,
    this.steps,
  );
  final String id, title, subtitle, takeaway;
  final Color accent;
  final IconData icon;
  final List<IllustratedGuideStep> steps;
}

/// General preparedness actions paraphrased from the source on each step.
const mitigationLessons = [
  MitigationLesson(
    'before-eruption',
    'Sebelum Erupsi',
    'Siapkan diri sebelum dibutuhkan.',
    Color(0xFF8FC4FF),
    Icons.backpack_outlined,
    'Ingat: informasi resmi, perlengkapan, dan petunjuk evakuasi.',
    [
      IllustratedGuideStep(
        'Kenali informasi resmi',
        'Pantau perkembangan gunung dan arahan PVMBG serta petugas setempat.',
        'Persiapan mengikuti kondisi dan rekomendasi yang berlaku.',
        'Mengandalkan kabar tanpa sumber.',
        GuideScene.radio,
        'Periksa sumber sebelum membagikan informasi.',
        bnpbPreparation,
      ),
      IllustratedGuideStep(
        'Siapkan tas siaga',
        'Siapkan makanan siap santap, air minum, obat pribadi, senter, baterai, dan uang secukupnya.',
        'Kebutuhan penting lebih mudah dijangkau saat diperlukan.',
        'Menunggu keadaan mendesak untuk berkemas.',
        GuideScene.bag,
        'Kumpulkan kebutuhan penting dalam tas yang mudah dibawa.',
        bnpbPreparation,
      ),
      IllustratedGuideStep(
        'Kenali petunjuk evakuasi',
        'Pelajari jalur dan tempat pengungsian yang ditetapkan pihak berwenang.',
        'Tujuan mengikuti ketentuan petugas, bukan perkiraan sendiri.',
        'Menganggap ilustrasi ini sebagai rute nyata.',
        GuideScene.route,
        'Ikuti rambu dan arahan di wilayah Anda.',
        bnpbPreparation,
      ),
      IllustratedGuideStep(
        'Siapkan pelindung abu',
        'Sediakan masker dan kacamata pelindung bersama perlengkapan siaga.',
        'Perlengkapan siap digunakan ketika terjadi hujan abu.',
        'Mengabaikan perlindungan pernapasan dan mata.',
        GuideScene.mask,
        'Masker dan kacamata punya fungsi berbeda.',
        bnpbPreparation,
      ),
      IllustratedGuideStep(
        'Latih rencana bersama keluarga',
        'Ikuti simulasi evakuasi di lingkungan Anda. Latih kembali langkahnya bersama anggota keluarga.',
        'Latihan membantu setiap orang mengenali petunjuk saat harus bergerak.',
        'Baru membahas rencana ketika perintah evakuasi sudah keluar.',
        GuideScene.meeting,
        'Berlatihlah bersama sebelum keadaan mendesak.',
        healthTraining,
      ),
      IllustratedGuideStep(
        'Atur bantuan transportasi',
        'Jika keluarga memerlukan kendaraan atau pendamping, hubungi orang yang bisa membantu dan cari tahu titik penjemputan dari petugas.',
        'Pengaturan sejak awal mengurangi waktu tunggu saat diminta mengungsi.',
        'Mengandalkan kendaraan yang belum disepakati.',
        GuideScene.vehicle,
        'Sepakati siapa yang membantu perjalanan.',
        cdcPreparation,
      ),
      IllustratedGuideStep(
        'Siapkan persediaan air bersih',
        'Isi wadah air minum yang bersih dan simpan di tempat yang diketahui seluruh keluarga.',
        'Persediaan air akan mudah dijangkau jika keluarga harus berlindung.',
        'Membiarkan wadah air minum terbuka saat abu turun.',
        GuideScene.water,
        'Sediakan air di dalam wadah tertutup.',
        cdcPreparation,
      ),
    ],
  ),
  MitigationLesson(
    'during-eruption',
    'Saat Erupsi',
    'Kurangi paparan, ikuti arahan.',
    Color(0xFFFFCF82),
    Icons.shield_outlined,
    'Ingat: arahan petugas lebih utama daripada ilustrasi.',
    [
      IllustratedGuideStep(
        'Utamakan arahan petugas',
        'Ikuti petunjuk pihak berwenang menuju tempat perlindungan atau pengungsian yang ditentukan.',
        'Kebutuhan evakuasi dapat berubah mengikuti keadaan.',
        'Menunggu label Awas sebelum mengikuti arahan mengungsi.',
        GuideScene.radio,
        'Dengarkan petunjuk yang berlaku di lokasi Anda.',
        healthGuide,
      ),
      IllustratedGuideStep(
        'Lindungi napas dan mata',
        'Gunakan masker serta kacamata pelindung ketika berada di area yang terdampak abu.',
        'Abu dapat mengganggu pernapasan dan mengiritasi mata.',
        'Memakai lensa kontak saat terpapar abu.',
        GuideScene.mask,
        'Lindungi hidung, mulut, dan mata dari abu.',
        healthGuide,
      ),
      IllustratedGuideStep(
        'Kurangi kegiatan di luar',
        'Jika tidak diarahkan mengungsi dan tempatnya aman, berlindung di dalam ruangan saat hujan abu.',
        'Paparan abu berkurang di tempat perlindungan.',
        'Tetap di bangunan yang harus dikosongkan.',
        GuideScene.shelter,
        'Berlindung tidak menggantikan perintah evakuasi.',
        healthGuide,
      ),
      IllustratedGuideStep(
        'Jauhi alur sungai',
        'Hindari sungai yang berhulu di gunung saat mengikuti evakuasi.',
        'Alur tersebut dapat dilalui lahar dan awan panas.',
        'Memilih sungai sebagai jalan pintas.',
        GuideScene.river,
        'Ilustrasi bahaya aliran, bukan peta lokasi.',
        healthGuide,
      ),
      IllustratedGuideStep(
        'Batasi abu yang masuk ke rumah',
        'Jika petugas meminta Anda berlindung di rumah, tutup pintu dan jendela luar serta matikan kipas atau AC yang menarik udara dari luar.',
        'Bukaan dan aliran udara dapat membawa abu masuk ke ruang berlindung.',
        'Bertahan di rumah setelah ada perintah evakuasi.',
        GuideScene.window,
        'Tutup bukaan antara ruang berlindung dan udara luar.',
        cdcPreparation,
      ),
      IllustratedGuideStep(
        'Tunda perjalanan saat hujan abu',
        'Tunda perjalanan yang bisa ditunda di jalan berabu. Jika harus mengungsi, ikuti petunjuk petugas mengenai transportasi.',
        'Abu dapat mengganggu pandangan dan kerja kendaraan.',
        'Berkendara untuk melihat letusan.',
        GuideScene.vehicle,
        'Batasi kendaraan di jalan yang tertutup abu.',
        usgsAsh,
      ),
      IllustratedGuideStep(
        'Lindungi kulit yang terpapar',
        'Jika perlu berada di luar, kenakan pakaian lengan panjang dan celana panjang bersama pelindung mata dan pernapasan.',
        'Pakaian membantu mengurangi kontak kulit dengan abu.',
        'Membiarkan kulit terbuka saat melewati area berabu.',
        GuideScene.mask,
        'Tutup bagian tubuh yang terpapar abu.',
        healthTraining,
      ),
    ],
  ),
  MitigationLesson(
    'evacuation',
    'Evakuasi',
    'Bergerak sesuai petunjuk setempat.',
    Color(0xFFFFA0AD),
    Icons.directions_walk_outlined,
    'Ingat: ikuti petugas, jauhi kawasan yang ditutup.',
    [
      IllustratedGuideStep(
        'Ikuti instruksi mengungsi',
        'Ikuti instruksi petugas untuk menjauh dari kawasan bahaya gunung api.',
        'Arahan setempat menyesuaikan ancaman di wilayah Anda.',
        'Menunda arahan demi menonton letusan.',
        GuideScene.route,
        'Arah panah hanya ilustrasi tindakan mengikuti petunjuk.',
        bnpbMessages,
      ),
      IllustratedGuideStep(
        'Hindari area berbahaya',
        'Jauhi area terbuka dan aliran sungai yang dinyatakan berbahaya oleh petugas.',
        'Letusan dapat melontarkan material dan menimbulkan aliran berbahaya.',
        'Membuat jalur pintas sendiri.',
        GuideScene.river,
        'Perhatikan larangan dan penutupan setempat.',
        bnpbMessages,
      ),
      IllustratedGuideStep(
        'Perhatikan pendampingan',
        'Bantu orang yang memerlukan pendampingan sesuai kemampuan dan koordinasikan dengan petugas.',
        'Kebutuhan setiap orang saat evakuasi berbeda.',
        'Mengabaikan keselamatan diri saat menolong.',
        GuideScene.help,
        'Sampaikan kebutuhan bantuan kepada petugas.',
        bnpbMessages,
      ),
      IllustratedGuideStep(
        'Bawa perlengkapan siaga',
        'Bawa perlengkapan penting yang sudah disiapkan dan ikuti instruksi selama evakuasi.',
        'Persiapan membantu memenuhi kebutuhan dasar di pengungsian.',
        'Meninggalkan petunjuk petugas demi barang.',
        GuideScene.bag,
        'Fokus pada kebutuhan penting dan arahan petugas.',
        bnpbMessages,
      ),
      IllustratedGuideStep(
        'Cari angkutan yang diarahkan petugas',
        'Jika tidak punya kendaraan, gunakan pengaturan yang telah disepakati atau minta informasi angkutan evakuasi kepada petugas.',
        'Petugas dapat mengarahkan Anda ke layanan yang tersedia saat itu.',
        'Berangkat ke titik jemput berdasarkan kabar yang belum dikonfirmasi.',
        GuideScene.vehicle,
        'Pastikan tujuan dan titik penjemputan.',
        cdcPreparation,
      ),
      IllustratedGuideStep(
        'Gunakan rute yang sedang dibuka',
        'Periksa arahan di persimpangan. Teruskan perjalanan melalui rute yang ditetapkan, termasuk bila petugas mengalihkan arus.',
        'Kondisi jalan bisa berubah dan jalur lain dapat terputus.',
        'Mengikuti jalan yang ditutup karena biasanya lebih cepat.',
        GuideScene.route,
        'Ikuti rambu menuju tempat pengungsian.',
        cdcPreparation,
      ),
      IllustratedGuideStep(
        'Pastikan obat pribadi ikut terbawa',
        'Saat berangkat, pastikan obat rutin yang sudah disiapkan berada pada orang atau pendamping yang memerlukannya.',
        'Kebutuhan pengobatan tetap ada selama perjalanan dan di pengungsian.',
        'Menunda evakuasi atau kembali ke area berbahaya untuk mencari barang.',
        GuideScene.bag,
        'Simpan obat bersama perlengkapan yang dibawa.',
        cdcPreparation,
      ),
    ],
  ),
  MitigationLesson(
    'after-eruption',
    'Pasca Erupsi',
    'Tetap waspada selama pemulihan.',
    Color(0xFF8EE1BE),
    Icons.health_and_safety_outlined,
    'Ingat: abu dan lahar masih perlu diwaspadai.',
    [
      IllustratedGuideStep(
        'Ikuti informasi pemulihan',
        'Pantau pengumuman dan perkembangan dari pihak berwenang selama berada di pengungsian.',
        'Kondisi dan petunjuk dapat berubah setelah erupsi.',
        'Menganggap berakhirnya letusan sebagai izin kembali.',
        GuideScene.radio,
        'Tetap perhatikan pengumuman petugas.',
        bpbdRecovery,
      ),
      IllustratedGuideStep(
        'Tetap lindungi diri',
        'Gunakan masker dan kacamata saat masih berada di wilayah terdampak abu.',
        'Abu tersisa masih dapat terhirup atau mengenai mata.',
        'Menganggap abu tersisa tidak berbahaya.',
        GuideScene.mask,
        'Perlindungan tetap diperlukan di area berabu.',
        bpbdRecovery,
      ),
      IllustratedGuideStep(
        'Waspadai lahar',
        'Jauhi aliran sungai yang berpotensi membawa material vulkanik, terutama ketika hujan.',
        'Hujan dapat menggerakkan kembali material di sungai.',
        'Mendekati sungai untuk melihat aliran.',
        GuideScene.river,
        'Lahar dapat terjadi setelah letusan.',
        bpbdRecovery,
      ),
      IllustratedGuideStep(
        'Bersihkan halaman dengan hati-hati',
        'Jika lokasi sudah boleh digunakan, basahi sedikit abu halaman sebelum dibersihkan; pakai sarung tangan.',
        'Langkah ini membantu mengurangi debu yang beterbangan.',
        'Menyapu abu kering hingga berhamburan.',
        GuideScene.clean,
        'Ilustrasi pembersihan permukaan tanah, bukan pekerjaan atap.',
        bnpbMessages,
      ),
      IllustratedGuideStep(
        'Dampingi anak di pengungsian',
        'Temani anak dan remaja selama tinggal di pengungsian. Hubungi petugas pendamping bila keluarga memerlukan dukungan.',
        'Kehadiran orang yang dikenal membantu anak menghadapi perubahan suasana.',
        'Membiarkan anak menghadapi situasi pengungsian sendiri.',
        GuideScene.meeting,
        'Duduk bersama dan dengarkan kebutuhan anak.',
        bpbdRecovery,
      ),
      IllustratedGuideStep(
        'Periksa lingkungan saat diizinkan pulang',
        'Setelah petugas menyatakan area boleh dimasuki, lihat kondisi rumah dan lingkungan dari tempat yang aman.',
        'Kerusakan bangunan dan timbunan abu bisa tetap ada setelah letusan.',
        'Langsung memasuki bangunan yang tampak rusak.',
        GuideScene.shelter,
        'Tunggu izin petugas sebelum memeriksa rumah.',
        healthTraining,
      ),
      IllustratedGuideStep(
        'Koordinasikan bantuan di posko',
        'Jika ingin membantu pembagian logistik, tanyakan kebutuhan kepada petugas posko dan ikuti pembagian tugas.',
        'Koordinasi membantu penyaluran bantuan sesuai kebutuhan warga.',
        'Berangkat sendiri ke area yang masih ditutup untuk membagikan bantuan.',
        GuideScene.help,
        'Sampaikan kesiapan membantu kepada petugas.',
        healthTraining,
      ),
    ],
  ),
];
