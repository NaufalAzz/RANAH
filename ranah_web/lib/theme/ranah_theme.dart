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
  static const muted = Color(0xFF596474);
  static const headerMuted = Color(0xFFC1C3D0);
  static const eruption = Color(0xFFD51E25);
  static const shelter = Color(0xFFF39A00);
  static const aid = Color(0xFF74839A);
}

abstract final class RanahTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: RanahColors.backgroundMiddle,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    colorScheme: ColorScheme.fromSeed(
      seedColor: RanahColors.primary,
      primary: RanahColors.primary,
      surface: RanahColors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: RanahColors.white, fontSize: 16),
      bodyMedium: TextStyle(color: RanahColors.white, fontSize: 16),
      bodySmall: TextStyle(color: RanahColors.white, fontSize: 12),
      labelLarge: TextStyle(fontSize: 16),
      labelMedium: TextStyle(fontSize: 14),
      labelSmall: TextStyle(fontSize: 12),
    ),
    iconTheme: const IconThemeData(color: RanahColors.white),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
