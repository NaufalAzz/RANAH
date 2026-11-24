import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

abstract final class AppBackground {
  static const decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF123650), Color(0xFF0F2B41), Color(0xFF164555)],
      stops: [0, .55, 1],
    ),
  );

  static const ringColor = Color(0x09FFFFFF);
  static const ringWidth = AppSpacing.xl;
}
