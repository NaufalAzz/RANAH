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
  static const focus = Color(0xFF006D86);
  static const error = Color(0xFFB42336);
  static const headerMuted = Color(0xFFC1C3D0);
  static const eruption = Color(0xFFD51E25);
  static const shelter = Color(0xFFF39A00);
  static const aid = Color(0xFF74839A);
}

abstract final class RanahLayout {
  /// Shared desktop content ceiling: wide enough for information-heavy pages
  /// while keeping long text and tables within a readable measure.
  static const maxContentWidth = 1480.0;
}

/// Shared dimensions and typography for page title bars.
abstract final class RanahPageHeaderStyle {
  static const minHeight = 88.0;
  static const horizontalPadding = 16.0;
  static const verticalPadding = 12.0;
  static const iconSize = 30.0;
  static const iconGap = 12.0;

  static const kicker = TextStyle(
    color: Color(0xFF91A8D0),
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const title = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const subtitle = TextStyle(
    color: Color(0xFFC1C8D7),
    fontSize: 13,
    height: 1.35,
  );
}

/// Shared map viewport sizing for page maps across responsive screen sizes.
abstract final class RanahMapLayout {
  static double heightFor({
    required double screenWidth,
    required double screenHeight,
  }) {
    final compact = screenWidth < 700;
    if (compact) return (screenHeight * .48).clamp(300.0, 440.0).toDouble();
    if (screenWidth < 1000) {
      return (screenHeight * .55).clamp(380.0, 560.0).toDouble();
    }
    return (screenHeight * .58).clamp(440.0, 680.0).toDouble();
  }
}

/// Shared spacing scale for page rhythm and component interiors.
abstract final class RanahSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

/// Shared corner sizes for controls, content surfaces, and rounded badges.
abstract final class RanahRadii {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const pill = 24.0;
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
    inputDecorationTheme: const InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(
        horizontal: RanahSpacing.lg,
        vertical: RanahSpacing.md,
      ),
      hintStyle: TextStyle(color: RanahColors.muted),
      labelStyle: TextStyle(color: RanahColors.muted),
      floatingLabelStyle: TextStyle(color: RanahColors.focus),
      errorStyle: TextStyle(color: RanahColors.error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RanahRadii.sm)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RanahRadii.sm)),
        borderSide: BorderSide(color: Color(0xFF7392AA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RanahRadii.sm)),
        borderSide: BorderSide(color: RanahColors.focus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RanahRadii.sm)),
        borderSide: BorderSide(color: RanahColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RanahRadii.sm)),
        borderSide: BorderSide(color: RanahColors.error, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RanahRadii.sm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RanahRadii.sm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RanahRadii.sm),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return RanahColors.muted;
        if (states.contains(WidgetState.selected)) return RanahColors.eruption;
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: Color(0xFFD5DDE7), width: 2),
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
