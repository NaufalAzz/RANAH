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
}

/// Only recognized navigation phrases can trigger navigation. Never calls a
/// number, requests location, or interprets an utterance as an emergency alert.
List<VoiceDestination> resolveVoiceCommand(String utterance) {
  var command = utterance
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  command = command.replaceFirst(
    RegExp(
      r'^(?:(?:tolong|buka|bukakan|tampilkan|lihat|ke|halaman|fitur|menu|saya ingin|saya mau)\s+)+',
    ),
    '',
  );
  const aliases = <VoiceDestination, List<String>>{
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
    VoiceDestination.map: ['peta', 'lihat peta', 'peta evakuasi'],
    VoiceDestination.activity: [
      'gunung',
      'status gunung',
      'status gunung api',
      'aktivitas gunung',
      'aktivitas gunung api',
      'info gunung',
      'informasi gunung',
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
    VoiceDestination.news: ['berita', 'informasi berita'],
    VoiceDestination.notifications: ['notifikasi', 'pemberitahuan'],
    VoiceDestination.menu: ['menu', 'layanan'],
  };
  // "Menu" alone is a destination; the prefix above only strips it when a
  // feature name follows. Broad evacuation requests need a choice.
  if (command == 'evakuasi') {
    return [VoiceDestination.guide, VoiceDestination.map];
  }
  return [
    for (final entry in aliases.entries)
      if (entry.value.contains(command)) entry.key,
  ];
}
