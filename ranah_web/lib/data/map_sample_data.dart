class SampleMountain {
  const SampleMountain({
    required this.name,
    required this.level,
    required this.color,
    required this.distance,
  });

  final String name;
  final String level;
  final int color;
  final String distance;
}

class SampleHazard {
  const SampleHazard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String name;
  final String description;
  final String icon;
  final int color;
}

const sampleMountains = <SampleMountain>[
  SampleMountain(
    name: 'Gunung Marapi',
    level: 'LEVEL II · WASPADA',
    color: 0xFFFFC928,
    distance: 'Jarak contoh: ±40 km dari Padang',
  ),
  SampleMountain(
    name: 'Gunung Talang',
    level: 'LEVEL I · NORMAL',
    color: 0xFF36B85C,
    distance: 'Jarak contoh: ±70 km dari Padang',
  ),
];

const sampleHazards = <SampleHazard>[
  SampleHazard(
    name: 'Tsunami',
    description: 'Contoh potensi wilayah pesisir; bukan peringatan aktif.',
    icon: 'tsunami',
    color: 0xFF38B8C5,
  ),
  SampleHazard(
    name: 'Banjir',
    description: 'Contoh potensi akibat curah hujan tinggi.',
    icon: 'flood',
    color: 0xFF42A5F5,
  ),
  SampleHazard(
    name: 'Gempa Bumi',
    description: 'Contoh potensi aktivitas tektonik.',
    icon: 'earthquake',
    color: 0xFF58C7A5,
  ),
];

const activityLevels = <({String label, String detail, int color})>[
  (label: 'Level I', detail: 'Normal', color: 0xFF2EAF55),
  (label: 'Level II', detail: 'Waspada', color: 0xFFFFCB2F),
  (label: 'Level III', detail: 'Siaga', color: 0xFFF47A27),
  (label: 'Level IV', detail: 'Awas', color: 0xFFE92C2D),
];
