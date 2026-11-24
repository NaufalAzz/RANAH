import 'package:flutter/material.dart';

/// Palette sampled from the supplied mockups and the existing app surfaces.
abstract final class AppColors {
  static const ink = Color(0xFF15243A);
  static const muted = Color(0xFF65748A);
  static const primary = Color(0xFF24106B);
  static const primarySoft = Color(0xFFEAE6F7);
  static const primaryDark = Color(0xFF131D39);
  static const headerStart = Color(0xFF10052E);
  static const bannerStart = Color(0xFF192B4C);
  static const bannerEnd = Color(0xFF133B50);
  static const brandTile = Color(0xFF0A2C4A);
  static const brandLabelPanel = Color(0xFF061B3B);
  static const teal = Color(0xFF087F83);
  static const tealGlow = Color(0xFF70D2D7);
  static const canvas = Color(0xFFF3F6FA);
  static const border = Color(0xFFE3E9F0);
  static const eruption = Color(0xFFC93D3D);
  static const danger = Color(0xFFE33C39);
  static const warning = Color(0xFFF4D22F);
  static const watch = Color(0xFFF07831);
  static const normal = Color(0xFF38A65B);
  static const onDark = Colors.white;
  static const mutedOnDark = Color(0xFFC5D7E4);
  static const bannerEyebrow = Color(0xFFA0DCD9);
  static const darkPanel = Color(0xFF123D5B);
  static const darkPanelBorder = Color(0xFF1D5778);
  static const emergencySurface = Color(0xFF702A39);
  static const emergencyBorder = Color(0xFFB03C4A);
  static const navigationIndicator = Color(0xFF265467);
  static const cardShadow = Color(0x26000A18);
  static const white = Colors.white;
}

abstract final class AppGradients {
  static const brandHeader = LinearGradient(
    colors: [Color(0xFF131B36), Color(0xFF1B2F4B), Color(0xFF111E36)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const pageBanner = LinearGradient(
    colors: [AppColors.bannerStart, AppColors.bannerEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const sectionBanner = LinearGradient(
    colors: [Color(0xFF192D4D), Color(0xFF1B4657)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const emergencyCard = LinearGradient(
    colors: [Color(0xFF5D1E2D), Color(0xFF3E1730)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const volcanicAccent = LinearGradient(
    colors: [Color(0xFFFF5238), Color(0xFFC92828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mitigationAccent = LinearGradient(
    colors: [Color(0xFF0BA39C), Color(0xFF066164)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Spacing values follow a 4 dp base unit.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadii {
  static const control = 10.0;
  static const compact = 14.0;
  static const card = 20.0;
  static const image = 16.0;
  static const pill = 32.0;
}

abstract final class AppSizes {
  static const minimumTapTarget = 48.0;
  static const iconSmall = 20.0;
  static const iconMedium = 24.0;
  static const brandMark = 48.0;
  static const brandIcon = 28.0;
  static const bannerIcon = 40.0;
  static const brandHeaderVerticalPadding = 16.0;
  static const pageBannerMinHeight = 88.0;
  static const bottomNavigationHeight = 68.0;
  static const bottomNavigationLabelClearance = 52.0;
  static const maxContentWidth = 560.0;
}

abstract final class AppTypography {
  static const headline = TextStyle(
    color: AppColors.ink,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static const pageTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const sectionTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const body = TextStyle(
    color: AppColors.ink,
    fontSize: 14,
    height: 1.45,
  );
  static const bodyLarge = TextStyle(
    color: AppColors.ink,
    fontSize: 16,
    height: 1.5,
  );
  static const bodyCompact = TextStyle(
    color: AppColors.ink,
    fontSize: 13,
    height: 1.4,
  );
  static const caption = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    height: 1.4,
  );
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  static const badge = TextStyle(
    color: AppColors.onDark,
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w800,
  );
  static const brandTitle = TextStyle(
    color: AppColors.onDark,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
  );
  static const bannerEyebrow = TextStyle(
    color: AppColors.bannerEyebrow,
    fontSize: 13,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
  static const bannerTitle = TextStyle(
    color: AppColors.onDark,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const bannerSubtitle = TextStyle(
    color: AppColors.mutedOnDark,
    fontSize: 13,
    height: 1.25,
  );
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineSmall: AppTypography.headline,
        titleLarge: AppTypography.pageTitle,
        titleMedium: AppTypography.sectionTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.label,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.onDark,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.onDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: Color(0xFFE5EBF2), width: 1.2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.bottomNavigationHeight,
        backgroundColor: AppColors.primaryDark,
        indicatorColor: AppColors.navigationIndicator,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.compact),
        ),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: AppColors.onDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(size: 23, color: AppColors.onDark),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTapTarget,
            AppSizes.minimumTapTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTapTarget,
            AppSizes.minimumTapTarget,
          ),
          elevation: 2,
          shadowColor: AppColors.cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.compact),
          ),
        ),
      ),
    );
  }
}
