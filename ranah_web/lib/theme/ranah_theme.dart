import 'package:flutter/material.dart';

abstract final class RanahColors {
  static const headerStart = Color(0xFF10042F);
  static const headerEnd = Color(0xFF08021E);
  static const banner = Color(0xFF17003E);
  static const backgroundStart = Color(0xFF0C3151);
  static const backgroundMiddle = Color(0xFF0C2B45);
  static const backgroundEnd = Color(0xFF13536B);
  static const primary = Color(0xFF21005E);
  static const cardBlue = Color(0xFF183F70);
  static const white = Colors.white;
  static const ink = Color(0xFF172742);
  static const muted = Color(0xFF7B879A);
  static const eruption = Color(0xFFE92C2D);
  static const shelter = Color(0xFFF39A00);
  static const aid = Color(0xFF74839A);
}

abstract final class RanahTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: RanahColors.backgroundMiddle,
    colorScheme: ColorScheme.fromSeed(
      seedColor: RanahColors.primary,
      primary: RanahColors.primary,
      surface: RanahColors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: RanahColors.white),
      bodySmall: TextStyle(color: RanahColors.white),
    ),
    iconTheme: const IconThemeData(color: RanahColors.white),
    splashFactory: InkRipple.splashFactory,
  );
}
