/// Coordinate reference captured from the public MAGMA Indonesia map.
/// Source: https://magma.esdm.go.id/ ; accessed 21 November 2026.
/// These are volcano locations, never computed centroids of hazard polygons.
class VolcanoReference {
  const VolcanoReference(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude, longitude;
  static const source = 'MAGMA Indonesia / PVMBG';
  static const sourceUrl = 'https://magma.esdm.go.id/';
  static const checkedAt = '21 November 2026';
}

String normalizeVolcanoName(String name) {
  final key = name
      .toLowerCase()
      .replaceFirst(RegExp(r'^\s*(?:gunung(?:\s+api)?|g\.)\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return key == 'lewotobilaki' ? 'lewotobilakilaki' : key;
}

VolcanoReference? volcanoReference(String name) =>
    volcanoReferences[normalizeVolcanoName(name)];
const volcanoReferences = <String, VolcanoReference>{
  'agung': VolcanoReference("Agung", -8.342, 115.508),
  'ambang': VolcanoReference("Ambang", 0.75, 124.42),
  'anakkrakatau': VolcanoReference("Anak Krakatau", -6.102, 105.423),
  'anakranakah': VolcanoReference("Anak Ranakah", -8.62, 120.52),
  'arjunowelirang': VolcanoReference("Arjuno Welirang", -7.725, 112.58),
  'awu': VolcanoReference("Awu", 3.682846, 125.45598),
  'bandaapi': VolcanoReference("Banda Api", -4.523, 129.881),
  'batur': VolcanoReference("Batur", -8.242, 115.375),
  'batutara': VolcanoReference("Batutara", -7.792, 123.579),
  'bromo': VolcanoReference("Bromo", -7.942, 112.95),
  'burnitelong': VolcanoReference("Bur Ni Telong", 4.769, 96.821),
  'ciremai': VolcanoReference("Ciremai", -6.892, 108.4),
  'colo': VolcanoReference("Colo", -0.162, 121.601),
  'dempo': VolcanoReference("Dempo", -4.03, 103.13),
  'dieng': VolcanoReference("Dieng", -7.2, 109.92),
  'dukono': VolcanoReference("Dukono", 1.693, 127.894),
  'ebulobo': VolcanoReference("Ebulobo", -8.82, 121.18),
  'egon': VolcanoReference("Egon", -8.676, 122.455),
  'galunggung': VolcanoReference("Galunggung", -7.25, 108.058),
  'gamalama': VolcanoReference("Gamalama", 0.8, 127.33),
  'gamkonora': VolcanoReference("Gamkonora", 1.38, 127.53),
  'gede': VolcanoReference("Gede", -6.77, 106.965),
  'guntur': VolcanoReference("Guntur", -7.143, 107.84),
  'hobal': VolcanoReference("Hobal", -8.5444, 123.585),
  'ibu': VolcanoReference("Ibu", 1.488, 127.63),
  'ijen': VolcanoReference("Ijen", -8.058, 114.242),
  'ilewerung': VolcanoReference("Ile Werung", -8.53, 123.57),
  'iliboleng': VolcanoReference("Ili Boleng", -8.342, 123.258),
  'ililewotolok': VolcanoReference("Ili Lewotolok", -8.272, 123.505),
  'inielika': VolcanoReference("Inielika", -8.73, 120.98),
  'inierie': VolcanoReference("Inierie", -8.875, 120.95),
  'iya': VolcanoReference("Iya", -8.897, 121.645),
  'kaba': VolcanoReference("Kaba", -3.52, 102.62),
  'karangetang': VolcanoReference("Karangetang", 2.78, 125.406),
  'kelimutu': VolcanoReference("Kelimutu", -8.77, 121.82),
  'kelud': VolcanoReference("Kelud", -7.93, 112.308),
  'kerinci': VolcanoReference("Kerinci", -1.697, 101.264),
  'kiebesi': VolcanoReference("Kie Besi", 0.32, 127.4),
  'lamongan': VolcanoReference("Lamongan", -7.979, 113.342),
  'lereboleng': VolcanoReference("Lereboleng", -8.365, 122.833),
  'lewotobilakilaki': VolcanoReference("Lewotobi Laki-laki", -8.5389, 122.7682),
  'lewotobiperempuan': VolcanoReference(
    "Lewotobi Perempuan",
    -8.5539,
    122.7805,
  ),
  'lokon': VolcanoReference("Lokon", 1.358, 124.792),
  'mahawu': VolcanoReference("Mahawu", 1.352, 124.865),
  'marapi': VolcanoReference("Marapi", -0.381, 100.473),
  'merapi': VolcanoReference("Merapi", -7.542, 110.442),
  'papandayan': VolcanoReference("Papandayan", -7.32, 107.73),
  'peutsague': VolcanoReference("Peut Sague", 4.914, 96.329),
  'raung': VolcanoReference("Raung", -8.125, 114.042),
  'rinjani': VolcanoReference("Rinjani", -8.42, 116.47),
  'rokatenda': VolcanoReference("Rokatenda", -8.32, 121.708),
  'ruang': VolcanoReference("Ruang", 2.3031, 125.3667),
  'salak': VolcanoReference("Salak", -6.72, 106.73),
  'sangeangapi': VolcanoReference("Sangeangapi", -8.2, 119.07),
  'semeru': VolcanoReference("Semeru", -8.108, 112.92),
  'seulawahagam': VolcanoReference("Seulawah Agam", 5.448, 95.658),
  'sinabung': VolcanoReference("Sinabung", 3.17, 98.392),
  'sirung': VolcanoReference("Sirung", -8.508, 124.13),
  'slamet': VolcanoReference("Slamet", -7.242, 109.208),
  'soputan': VolcanoReference("Soputan", 1.1145, 124.737),
  'sorikmarapi': VolcanoReference("Sorikmarapi", 0.686, 99.537),
  'sumbing': VolcanoReference("Sumbing", -7.384, 110.07),
  'sundoro': VolcanoReference("Sundoro", -7.3, 109.992),
  'talang': VolcanoReference("Talang", -0.978, 100.679),
  'tambora': VolcanoReference("Tambora", -8.25, 118.0),
  'tandikat': VolcanoReference("Tandikat", -0.39, 100.331),
  'tangkoko': VolcanoReference("Tangkoko", 1.518, 125.185),
  'tangkubanparahu': VolcanoReference("Tangkuban Parahu", -6.77, 107.6),
  'wurlali': VolcanoReference("Wurlali", -7.125, 128.675),
};
