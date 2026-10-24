import 'package:flutter/material.dart';

enum SampleNotificationKind { volcano, earthquake }

enum SampleNotificationDestination { volcanicActivity, volcanoReport }

class SampleNotification {
  const SampleNotification({
    required this.kind,
    required this.level,
    required this.time,
    required this.title,
    required this.message,
    required this.source,
    this.destination,
    this.volcanoName,
  });

  final SampleNotificationKind kind;
  final String level;
  final String time;
  final String title;
  final String message;
  final String source;
  final SampleNotificationDestination? destination;
  final String? volcanoName;

  IconData get icon => switch (kind) {
    SampleNotificationKind.volcano => Icons.crisis_alert_outlined,
    SampleNotificationKind.earthquake => Icons.vibration_rounded,
  };
}

/// These entries demonstrate the notification history layout only.
/// They are not live warnings and are not supplied by BMKG or PVMBG.
const sampleNotifications = <SampleNotification>[
  SampleNotification(
    kind: SampleNotificationKind.volcano,
    level: 'BAHAYA',
    time: '08:15',
    title: 'CONTOH PERINGATAN GUNUNG API',
    message: 'Simulasi riwayat perubahan status gunung api. Tidak mewakili status atau arahan evakuasi nyata.',
    source: 'Data simulasi lokal · Pembaruan contoh 25 Oktober 2026',
    destination: SampleNotificationDestination.volcanicActivity,
  ),
  SampleNotification(
    kind: SampleNotificationKind.earthquake,
    level: 'INFORMASI',
    time: '08:10',
    title: 'CONTOH INFORMASI GEMPA',
    message: 'Simulasi riwayat notifikasi gempa. Tidak memuat kejadian, magnitudo, atau lokasi real-time.',
    source: 'Sumber yang direncanakan: BMKG · Belum terintegrasi',
  ),
  SampleNotification(
    kind: SampleNotificationKind.volcano,
    level: 'WASPADA',
    time: '07:45',
    title: 'CONTOH PEMBARUAN GUNUNG MARAPI',
    message: 'Contoh notifikasi manual untuk data aktivitas Gunung Marapi; bukan informasi resmi atau terkini.',
    source: 'Data simulasi lokal · Admin belum terhubung',
    destination: SampleNotificationDestination.volcanoReport,
    volcanoName: 'Gunung Marapi',
  ),
  SampleNotification(
    kind: SampleNotificationKind.earthquake,
    level: 'INFORMASI',
    time: '07:20',
    title: 'CONTOH RIWAYAT GEMPA',
    message: 'Konten demonstrasi untuk notifikasi gempa. Verifikasi informasi bencana melalui kanal resmi.',
    source: 'Sumber yang direncanakan: BMKG · Belum terintegrasi',
  ),
];
