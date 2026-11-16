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

/// Match whole keywords anywhere in a final utterance, ignoring filler words.
/// Collect every matching destination once; shared keywords remain ambiguous.
List<VoiceDestination> resolveVoiceCommand(String utterance) {
  final command = utterance
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (command.isEmpty ||
      RegExp(r'\b(jangan|jgn|tidak|batal)\b').hasMatch(command))
    return [];
  final words = command.split(' ').toSet();
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
    VoiceDestination.home: 'beranda awal home',
    VoiceDestination.menu: 'menu layanan',
  };
  final results = [
    for (final entry in keywords.entries)
      if (entry.value.split(' ').any(words.contains)) entry.key,
  ];
  // “Menu” often introduces a feature name, e.g. “buka menu kontak”.
  // Keep it as a destination only when no specific feature was requested.
  if (results.length > 1 &&
      words.contains('menu') &&
      !words.contains('layanan')) {
    results.remove(VoiceDestination.menu);
  }
  return results;
}
