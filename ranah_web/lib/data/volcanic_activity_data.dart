class ActivityLevelPresentation {
  const ActivityLevelPresentation({
    required this.level,
    required this.name,
    required this.color,
    required this.textColor,
    required this.badgeColor,
  });

  final int level;
  final String name;
  final int color;

  /// Light version for readable status text on dark RANAH surfaces.
  final int textColor;

  /// Dark version for white status text in compact badges.
  final int badgeColor;
}

const activityLevels = <ActivityLevelPresentation>[
  ActivityLevelPresentation(
    level: 4,
    name: 'Awas',
    color: 0xFFE53935,
    textColor: 0xFFFF8A80,
    badgeColor: 0xFFA61B1B,
  ),
  ActivityLevelPresentation(
    level: 3,
    name: 'Siaga',
    color: 0xFFF27822,
    textColor: 0xFFFFB36B,
    badgeColor: 0xFFA84300,
  ),
  ActivityLevelPresentation(
    level: 2,
    name: 'Waspada',
    color: 0xFFFFB51B,
    textColor: 0xFFFFD166,
    badgeColor: 0xFF805A00,
  ),
  ActivityLevelPresentation(
    level: 1,
    name: 'Normal',
    color: 0xFF39B85B,
    textColor: 0xFF6FE3A4,
    badgeColor: 0xFF176B3A,
  ),
];

const unknownActivityLevel = ActivityLevelPresentation(
  level: 0,
  name: 'Belum diketahui',
  color: 0xFF9AA7B5,
  textColor: 0xFFD5E2ED,
  badgeColor: 0xFF596474,
);

ActivityLevelPresentation activityLevelPresentation(int? level) =>
    activityLevels.firstWhere(
      (item) => item.level == level,
      orElse: () => unknownActivityLevel,
    );
