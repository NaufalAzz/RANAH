class ActivityLevelPresentation {
  const ActivityLevelPresentation({
    required this.level,
    required this.name,
    required this.color,
  });

  final int level;
  final String name;
  final int color;
}

const activityLevels = <ActivityLevelPresentation>[
  ActivityLevelPresentation(level: 4, name: 'Awas', color: 0xFFE53935),
  ActivityLevelPresentation(level: 3, name: 'Siaga', color: 0xFFF27822),
  ActivityLevelPresentation(level: 2, name: 'Waspada', color: 0xFFFFB51B),
  ActivityLevelPresentation(level: 1, name: 'Normal', color: 0xFF39B85B),
];

const unknownActivityLevel = ActivityLevelPresentation(
  level: 0,
  name: 'Belum diketahui',
  color: 0xFF9AA7B5,
);

ActivityLevelPresentation activityLevelPresentation(int? level) =>
    activityLevels.firstWhere(
      (item) => item.level == level,
      orElse: () => unknownActivityLevel,
    );
