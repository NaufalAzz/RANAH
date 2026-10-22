import 'package:flutter/material.dart';

enum NotificationKind {
  earthquake,
  volcanoActivity,
  volcanoStatus,
  latestNews,
  evacuation,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    this.targetId,
    required this.title,
    required this.timeLabel,
    required this.summary,
    required this.icon,
    required this.accent,
  });

  final String id;
  final NotificationKind kind;

  /// Stable ID of the related record, ready to map to backend/FCM payloads.
  final String? targetId;
  final String title;
  final String timeLabel;
  final String summary;
  final IconData icon;
  final Color accent;

  String get kindLabel => switch (kind) {
    NotificationKind.earthquake => 'Gempa bumi',
    NotificationKind.volcanoActivity => 'Aktivitas gunung api',
    NotificationKind.volcanoStatus => 'Status gunung api',
    NotificationKind.latestNews => 'Berita terbaru',
    NotificationKind.evacuation => 'Informasi evakuasi',
  };
}
