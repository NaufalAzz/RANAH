import 'package:flutter/material.dart';

import '../models/notification_item.dart';

// Contoh lokal untuk pratinjau UI, bukan peringatan atau laporan kejadian aktif.
const sampleNotifications = <NotificationItem>[
  NotificationItem(
    id: 'notification-earthquake-preview',
    kind: NotificationKind.earthquake,
    title: 'Rincian gempa belum tersedia',
    timeLabel: 'Contoh waktu',
    summary: 'Pratinjau notifikasi gempa. Waktu, lokasi, magnitudo, dan kedalaman belum tersedia. Informasi aktual akan merujuk BMKG.',
    icon: Icons.vibration_rounded,
    accent: Color(0xFFE34F54),
  ),
  NotificationItem(
    id: 'notification-volcano-activity-preview',
    kind: NotificationKind.volcanoActivity,
    targetId: 'sample-volcano-report-unavailable',
    title: 'Pembaruan aktivitas belum tersedia',
    timeLabel: 'Contoh waktu',
    summary: 'Pratinjau notifikasi gunung api. Status, rekomendasi, waktu pembaruan, dan sumber menunggu verifikasi admin.',
    icon: Icons.landscape_rounded,
    accent: Color(0xFFE47B43),
  ),
  NotificationItem(
    id: 'notification-volcano-status-preview',
    kind: NotificationKind.volcanoStatus,
    targetId: 'sample-volcano-status-unavailable',
    title: 'Informasi status belum tersedia',
    timeLabel: 'Contoh waktu',
    summary: 'Pratinjau perubahan status gunung api. Data gunung, tingkat aktivitas, dan laporan resmi belum tersedia.',
    icon: Icons.monitor_heart_outlined,
    accent: Color(0xFFE47B43),
  ),
  NotificationItem(
    id: 'notification-news-preview',
    kind: NotificationKind.latestNews,
    targetId: 'news-emergency-supplies',
    title: 'Contoh: Siapkan kebutuhan untuk keadaan darurat',
    timeLabel: 'Contoh waktu',
    summary: 'Pratinjau tautan berita. Buka artikel contoh tentang persiapan kebutuhan darurat.',
    icon: Icons.newspaper_rounded,
    accent: Color(0xFF5273C8),
  ),
  NotificationItem(
    id: 'notification-evacuation-preview',
    kind: NotificationKind.evacuation,
    targetId: 'sample-evacuation-map',
    title: 'Informasi evakuasi belum tersedia',
    timeLabel: 'Contoh waktu',
    summary: 'Pratinjau informasi evakuasi. Peta hanya berisi ilustrasi dan belum memuat rute atau titik aman resmi.',
    icon: Icons.route_rounded,
    accent: Color(0xFF3C9B84),
  ),
];
