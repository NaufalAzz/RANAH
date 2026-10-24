import 'package:flutter/material.dart';

enum MitigationStage { before, during, evacuation, after }

class MitigationGuide {
  const MitigationGuide({
    required this.stage,
    required this.label,
    required this.accent,
    required this.cardColors,
    required this.steps,
    required this.notice,
    this.placeholder = false,
  });

  final MitigationStage stage;
  final String label;
  final Color accent;
  final List<Color> cardColors;
  final List<String> steps;
  final String notice;
  final bool placeholder;
}

/// Content mirrors the local guide data used by the mobile application.
/// It remains general educational information, not live official advice.
const mitigationGuides = <MitigationGuide>[
  MitigationGuide(
    stage: MitigationStage.before,
    label: 'Sebelum\nErupsi',
    accent: Color(0xFF1762B4),
    cardColors: [Color(0xFF164576), Color(0xFF174E7B)],
    notice: 'Sumber: Buku Saku Menghadapi Bencana, Badan Nasional Penanggulangan Bencana (BNPB), diakses 23 Oktober 2026. Ringkasan edukasi umum; ikuti arahan terbaru PVMBG dan BPBD.',
    steps: [
      'Kenali tanda peringatan dan ikuti informasi aktivitas gunung api dari sumber resmi.',
      'Siapkan tas siaga berisi dokumen penting, obat pribadi, pakaian, air, dan kebutuhan dasar.',
      'Pelajari jalur evakuasi dan titik kumpul yang telah ditetapkan oleh pihak berwenang.',
      'Susun rencana komunikasi keluarga dan sepakati tempat bertemu jika terpisah.',
      'Catat kontak darurat dari instansi resmi dan simpan agar mudah ditemukan.',
      'Pastikan anggota keluarga mengetahui tindakan yang perlu dilakukan saat peringatan diberikan.',
      'Lindungi dokumen penting dengan wadah yang tahan air dan mudah dibawa.',
      'Siapkan kebutuhan khusus anak, lansia, penyandang disabilitas, dan hewan peliharaan.',
    ],
  ),
  MitigationGuide(
    stage: MitigationStage.during,
    label: 'Saat Erupsi',
    accent: Color(0xFFC88600),
    cardColors: [Color(0xFF424940), Color(0xFF4B5D50)],
    notice: 'Sumber: Buku Saku Menghadapi Bencana, Badan Nasional Penanggulangan Bencana (BNPB), diakses 23 Oktober 2026. Ringkasan edukasi umum; ikuti arahan terbaru PVMBG dan BPBD.',
    steps: [
      'Tetap tenang dan ikuti peringatan serta arahan petugas di wilayah Anda.',
      'Jika berada di dalam bangunan dan belum diminta mengungsi, tutup pintu serta jendela untuk mengurangi abu masuk.',
      'Gunakan masker dan pelindung mata saat harus berada di luar ketika abu vulkanik turun.',
      'Jauhi zona bahaya dan jangan mendekati kawah atau area yang ditutup petugas.',
      'Hindari lembah dan aliran sungai yang berhulu di gunung karena dapat dilalui lahar.',
      'Bantu anak-anak, lansia, dan orang yang membutuhkan bantuan tanpa menghambat evakuasi.',
      'Bawa tas siaga hanya jika dapat dijangkau dengan aman dan arahan petugas memungkinkan.',
      'Jangan kembali ke rumah atau zona yang ditinggalkan sebelum dinyatakan aman oleh pihak berwenang.',
    ],
  ),
  MitigationGuide(
    stage: MitigationStage.evacuation,
    label: 'Evakuasi',
    accent: Color(0xFFBD2934),
    cardColors: [Color(0xFF493942), Color(0xFF41465A)],
    notice: 'Sumber: Buku Saku Menghadapi Bencana, Badan Nasional Penanggulangan Bencana (BNPB), diakses 23 Oktober 2026. Ringkasan edukasi umum; ikuti arahan terbaru PVMBG dan BPBD.',
    steps: [
      'Mulai evakuasi saat diperintahkan petugas atau sesuai informasi resmi yang berlaku.',
      'Gunakan jalur dan tempat tujuan evakuasi yang telah ditetapkan; jangan memilih jalan pintas sendiri.',
      'Berangkat bersama keluarga dan bantu anak-anak, lansia, serta orang yang membutuhkan pendampingan.',
      'Bawa obat dan kebutuhan penting yang dapat diambil segera tanpa menunda keberangkatan.',
      'Lindungi hidung, mulut, dan mata dari abu menggunakan perlengkapan yang sesuai.',
      'Jauhi lembah, aliran sungai, jembatan yang ditutup, dan area yang dinyatakan berbahaya.',
      'Sampaikan tujuan evakuasi kepada keluarga bila aman untuk menghubungi mereka.',
      'Setibanya di tempat evakuasi, lapor kepada petugas dan ikuti arahan berikutnya.',
    ],
  ),
  MitigationGuide(
    stage: MitigationStage.after,
    label: 'Pasca\nErupsi',
    accent: Color(0xFF168447),
    cardColors: [Color(0xFF174B54), Color(0xFF1B6560)],
    notice: 'Sumber: Buku Saku Menghadapi Bencana, Badan Nasional Penanggulangan Bencana (BNPB), diakses 23 Oktober 2026. Ringkasan edukasi umum; ikuti arahan terbaru PVMBG dan BPBD.',
    steps: [
      'Tetap berada di tempat aman sampai pemerintah atau petugas menyatakan Anda boleh kembali.',
      'Periksa informasi resmi untuk mengetahui kondisi dan rekomendasi terbaru sebelum bepergian.',
      'Hindari bangunan yang rusak dan laporkan kerusakan berbahaya kepada petugas.',
      'Jauhi sungai dan aliran lahar; material vulkanik dapat terbawa hujan setelah erupsi.',
      'Gunakan masker dan pelindung mata saat harus berada di area yang masih berdebu.',
      'Lindungi persediaan makanan dan air; jangan konsumsi yang terkena abu atau kotoran.',
      'Bersihkan abu dengan hati-hati dan lembapkan terlebih dahulu agar tidak mudah beterbangan.',
      'Periksa kondisi keluarga dan ikuti arahan petugas terkait bantuan serta pemulihan.',
    ],
  ),
];
