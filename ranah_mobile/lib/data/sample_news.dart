import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../theme/app_theme.dart';

/// Data lokal untuk pratinjau fondasi UI; bukan informasi bencana aktual.
const sampleNews = <NewsItem>[
  NewsItem(
    id: 'news-volcano-information',
    category: 'Erupsi',
    title: 'Contoh: Kenali informasi resmi aktivitas gunung api',
    summary: 'Contoh konten untuk pratinjau. Periksa informasi terbaru dari sumber resmi.',
    body: 'Sebelum membagikan informasi aktivitas gunung api, periksa nama gunung, sumber, waktu pembaruan, dan rekomendasi yang tercantum. Gunakan kanal resmi yang dirujuk oleh petugas daerah. Hindari meneruskan pesan yang tidak memiliki sumber atau tanggal yang jelas.\n\nArtikel ini merupakan contoh konten edukasi, bukan laporan aktivitas gunung api terkini.',
    publishedAt: 'Contoh data',
    icon: Icons.landscape_rounded,
    accent: AppColors.eruption,
  ),
  NewsItem(
    id: 'news-emergency-supplies',
    category: 'Pengungsian',
    title: 'Contoh: Siapkan kebutuhan untuk keadaan darurat',
    summary: 'Contoh konten kesiapsiagaan yang nantinya dikelola melalui panel admin.',
    body: 'Rencana evakuasi keluarga dapat memuat kontak penting dan kebutuhan yang disesuaikan untuk setiap anggota keluarga. Pastikan informasi rute dan titik evakuasi diperoleh dari pemerintah daerah atau petugas yang berwenang.\n\nArtikel ini contoh konten kesiapsiagaan, bukan panduan evakuasi untuk lokasi tertentu.',
    publishedAt: 'Contoh data',
    icon: Icons.backpack_outlined,
    accent: AppColors.teal,
  ),
  NewsItem(
    id: 'news-evacuation-routes',
    category: 'Bantuan',
    title: 'Contoh: Cari tahu jalur evakuasi di sekitar Anda',
    summary: 'Contoh konten lokal. Ikuti arahan resmi petugas di wilayah Anda.',
    body: 'Informasi bantuan dapat berbeda menurut lokasi dan waktu. Sebelum mendatangi lokasi atau membagikan pengumuman, periksa keterangan dari pemerintah daerah atau petugas setempat.\n\nArtikel ini contoh konten; tidak mengumumkan posko atau layanan bantuan yang sedang beroperasi.',
    publishedAt: 'Contoh data',
    icon: Icons.route_rounded,
    accent: Color(0xFFB7791F),
  ),
];
