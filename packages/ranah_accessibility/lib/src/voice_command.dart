enum VoiceDestination {
  home('Beranda'),
  guide('Panduan'),
  map('Peta'),
  activity('Aktivitas Gunung'),
  contacts('Kontak Darurat'),
  news('Berita'),
  notifications('Notifikasi'),
  menu('Menu');

  const VoiceDestination(this.label);
  final String label;

  String get description => switch (this) {
    home => 'Kembali ke halaman awal RANAH',
    guide => 'Panduan mitigasi dan keselamatan gunung api',
    map => 'Peta, lokasi, dan kawasan rawan gunung api',
    activity => 'Laporan dan tingkat aktivitas gunung api',
    contacts => 'Nomor layanan bantuan dan pengaduan',
    news => 'Berita dan informasi, termasuk gunung api',
    notifications => 'Pemberitahuan dan peringatan yang tersedia',
    menu => 'Daftar layanan RANAH',
  };
}

/// Exact feature names take precedence over general keywords. A broad keyword
/// can match several existing features; no arbitrary result is auto-selected.
/// Only final recognition results should be passed here by the voice panel.
List<VoiceDestination> resolveVoiceCommand(String utterance) {
  var command = utterance
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (RegExp(r'\b(jangan|jgn|tidak|batal)\b').hasMatch(command)) return [];
  command = command
      .replaceFirst(
        RegExp(
          r'^(?:(?:tolong|buka|bukakan|tampilkan|lihat|ke|halaman|fitur|menu|saya ingin|saya mau)\s+)+',
        ),
        '',
      )
      .replaceFirst(RegExp(r'\s+(dong|ya|tolong)$'), '');
  if (command.isEmpty) return [];

  const exactNames = <VoiceDestination, List<String>>{
    VoiceDestination.home: [
      'beranda',
      'awal',
      'kembali ke awal',
      'kembali ke beranda',
    ],
    VoiceDestination.guide: [
      'panduan',
      'mitigasi',
      'panduan mitigasi',
      'panduan erupsi',
      'petunjuk',
      'panduan evakuasi',
    ],
    VoiceDestination.map: ['peta', 'peta evakuasi', 'peta gunung'],
    VoiceDestination.activity: [
      'status gunung',
      'status gunung api',
      'aktivitas gunung',
      'aktivitas gunung api',
      'laporan gunung',
    ],
    VoiceDestination.contacts: [
      'kontak',
      'kontak darurat',
      'nomor petugas',
      'hubungi petugas',
      'telepon petugas',
      'bantuan',
      'nomor darurat',
    ],
    VoiceDestination.news: ['berita', 'berita gunung', 'informasi berita'],
    VoiceDestination.notifications: ['notifikasi', 'pemberitahuan'],
    VoiceDestination.menu: ['menu', 'layanan'],
  };
  final exact = [
    for (final entry in exactNames.entries)
      if (entry.value.contains(command)) entry.key,
  ];
  if (exact.isNotEmpty) return exact;

  // A query must match every meaningful word in a feature's vocabulary.
  // This avoids opening a menu merely because a longer unknown sentence
  // happens to contain one recognized word (or a substring such as "petani").
  final words = command
      .split(' ')
      .where((word) => !const {'tentang', 'untuk', 'di', 'yang'}.contains(word))
      .toSet();
  if (words.isEmpty) return [];
  const keywords = <VoiceDestination, String>{
    VoiceDestination.activity:
        'gunung api aktivitas status laporan informasi info vulkanik',
    VoiceDestination.map:
        'peta lokasi zona kawasan rawan gunung api evakuasi jalur rute',
    VoiceDestination.guide:
        'panduan mitigasi petunjuk keselamatan erupsi gunung api evakuasi',
    VoiceDestination.news: 'berita informasi info artikel gunung api erupsi',
    VoiceDestination.contacts:
        'kontak darurat telepon nomor petugas bantuan pengaduan',
    VoiceDestination.notifications: 'notifikasi pemberitahuan peringatan',
    VoiceDestination.home: 'beranda awal',
    VoiceDestination.menu: 'menu layanan',
  };
  return [
    for (final entry in keywords.entries)
      if (words.every(entry.value.split(' ').contains)) entry.key,
  ];
}
