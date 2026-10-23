import 'package:flutter/material.dart';

import '../models/mitigation_guide.dart';

const _bnpbGuideTitle = 'Buku Saku Menghadapi Bencana';
const _bnpbOrganization = 'Badan Nasional Penanggulangan Bencana (BNPB)';
const _bnpbUrl =
    'https://bnpb.go.id/storage/app/media/Buku%20BNPB/Buku%20Saku%20Bencana%20BNPB.pdf';
const _sourceAccessedAt = '23 Oktober 2026';

// Konten lokal awal; nantinya dapat diganti dengan panduan yang dikelola admin.
const mitigationGuides = <MitigationGuide>[
  MitigationGuide(
    id: 'before-eruption',
    title: 'Sebelum Erupsi',
    color: Color(0xFF1760A7),
    icon: Icons.inventory_2_outlined,
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
    sourceTitle: _bnpbGuideTitle,
    sourceOrganization: _bnpbOrganization,
    sourceUrl: _bnpbUrl,
    sourceAccessedAt: _sourceAccessedAt,
  ),
  MitigationGuide(
    id: 'during-eruption',
    title: 'Saat Erupsi',
    color: Color(0xFFB57912),
    icon: Icons.warning_amber_rounded,
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
    sourceTitle: _bnpbGuideTitle,
    sourceOrganization: _bnpbOrganization,
    sourceUrl: _bnpbUrl,
    sourceAccessedAt: _sourceAccessedAt,
  ),
  MitigationGuide(
    id: 'evacuation',
    title: 'Evakuasi',
    color: Color(0xFFA52D38),
    icon: Icons.directions_walk_rounded,
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
    sourceTitle: _bnpbGuideTitle,
    sourceOrganization: _bnpbOrganization,
    sourceUrl: _bnpbUrl,
    sourceAccessedAt: _sourceAccessedAt,
  ),
  MitigationGuide(
    id: 'after-eruption',
    title: 'Pasca Erupsi',
    color: Color(0xFF14804C),
    icon: Icons.health_and_safety_outlined,
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
    sourceTitle: _bnpbGuideTitle,
    sourceOrganization: _bnpbOrganization,
    sourceUrl: _bnpbUrl,
    sourceAccessedAt: _sourceAccessedAt,
  ),
];
